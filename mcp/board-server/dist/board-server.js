import { fileURLToPath } from 'url';
import path from 'path';
import dotenv from 'dotenv';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
// ESM equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Load .env from project root
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
const DEFAULT_BOARD_ID = process.env.MCP_BOARD_ID || '';
const API_URL = process.env.MCP_API_URL; // e.g. https://app.example.com
const API_KEY = process.env.MCP_API_KEY; // e.g. sk_live_xxxxx
const useRestApi = !!(API_URL && API_KEY);
// ─── Data source: REST API or Prisma ─────────────────────────────────────────
// Prisma client — dynamically imported from project's @prisma/client at runtime
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let prisma = null;
async function getPrisma() {
    if (!prisma) {
        // Dynamic import — resolved from project's node_modules at runtime
        const prismaModule = '@prisma/client';
        const { PrismaClient } = await import(prismaModule);
        prisma = new PrismaClient();
    }
    return prisma;
}
async function fetchBoardRest(boardId) {
    const res = await fetch(`${API_URL}/api/v1/boards/${boardId}`, {
        headers: { Authorization: `Bearer ${API_KEY}` },
    });
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`REST API error ${res.status}: ${body}`);
    }
    const json = await res.json();
    return json.data;
}
async function fetchCardRest(cardId) {
    const res = await fetch(`${API_URL}/api/v1/boards/cards/${cardId}`, {
        headers: { Authorization: `Bearer ${API_KEY}` },
    });
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`REST API error ${res.status}: ${body}`);
    }
    const json = await res.json();
    return json.data;
}
async function fetchBoardPrisma(boardId) {
    const db = await getPrisma();
    return db.board.findUnique({
        where: { id: boardId },
        include: {
            columns: {
                orderBy: { order: 'asc' },
                include: {
                    cards: {
                        where: { archivedAt: null },
                        orderBy: { order: 'asc' },
                        include: {
                            assignees: {
                                include: {
                                    person: {
                                        select: { firstName: true, lastName: true },
                                    },
                                },
                            },
                            tags: { include: { tag: true } },
                            checklists: { include: { items: true } },
                            _count: { select: { comments: true } },
                        },
                    },
                },
            },
        },
    });
}
async function fetchCardPrisma(cardId) {
    const db = await getPrisma();
    return db.boardCard.findUnique({
        where: { id: cardId },
        include: {
            column: {
                select: {
                    name: true,
                    status: true,
                    board: { select: { name: true } },
                },
            },
            assignees: {
                include: {
                    person: { select: { firstName: true, lastName: true } },
                },
            },
            tags: { include: { tag: true } },
            checklists: {
                orderBy: { order: 'asc' },
                include: { items: { orderBy: { order: 'asc' } } },
            },
            comments: {
                take: 20,
                orderBy: { createdAt: 'desc' },
                include: {
                    author: { select: { firstName: true, lastName: true } },
                },
            },
            activities: {
                take: 20,
                orderBy: { createdAt: 'desc' },
                include: {
                    author: { select: { firstName: true, lastName: true } },
                },
            },
            links: true,
            blockedByCard: { select: { id: true, title: true } },
        },
    });
}
// ─── Formatting helpers ──────────────────────────────────────────────────────
function stripHtml(html) {
    return html
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<\/p>/gi, '\n')
        .replace(/<[^>]+>/g, '')
        .replace(/&nbsp;/g, ' ')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .trim();
}
function formatDate(date) {
    return new Date(date).toLocaleDateString('ru-RU');
}
function getAssigneeNames(assignees) {
    return (assignees
        .map((a) => `${a.person.firstName} ${a.person.lastName}`.trim())
        .join(', ') || 'none');
}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function formatBoardText(board) {
    const now = new Date();
    let totalCards = 0;
    let blockedCount = 0;
    let overdueCount = 0;
    const lines = [`# ${board.name}`, ''];
    for (const column of board.columns) {
        const cards = column.cards || [];
        const cardCount = cards.length;
        totalCards += cardCount;
        const status = column.status || '';
        lines.push(`## ${column.name}` +
            `${status ? ` (${status})` : ''}` +
            ` — ${cardCount} cards`);
        lines.push(`   Column ID: ${column.id}`);
        lines.push('');
        if (cardCount === 0) {
            lines.push('_No cards_');
            lines.push('');
            continue;
        }
        for (let i = 0; i < cards.length; i++) {
            const card = cards[i];
            const priorityLabel = card.priority && card.priority !== 'NONE'
                ? `[${card.priority}] `
                : '';
            lines.push(`### ${i + 1}. ${priorityLabel}${card.title}`);
            lines.push(`   ID: ${card.id}`);
            // Assignees
            const assignees = card.assignees || [];
            lines.push(`   Assignees: ${getAssigneeNames(assignees)}`);
            // Due date
            if (card.dueDate) {
                const due = new Date(card.dueDate);
                const overdue = due < now && status !== 'done';
                lines.push(`   Due: ${formatDate(due)}` +
                    `${overdue ? ' ⚠ OVERDUE' : ''}`);
                if (overdue)
                    overdueCount++;
            }
            // Blocked
            if (card.isBlocked) {
                blockedCount++;
                lines.push(`   ⛔ BLOCKED` +
                    `${card.blockedReason ? `: ${card.blockedReason}` : ''}`);
            }
            // Tags
            const tags = card.tags || [];
            const tagNames = tags
                .map((t) => `#${t.tag.name}`)
                .join(', ');
            if (tagNames) {
                lines.push(`   Tags: ${tagNames}`);
            }
            // Checklists summary
            if (card.checklists && card.checklists.length > 0) {
                const totalItems = card.checklists.reduce((sum, cl) => sum + (cl.items?.length || 0), 0);
                const doneItems = card.checklists.reduce((sum, cl) => sum +
                    (cl.items?.filter((item) => item.completed).length || 0), 0);
                lines.push(`   Checklist: ${doneItems}/${totalItems} done`);
            }
            else if (card._count?.checklists > 0) {
                lines.push(`   Checklists: ${card._count.checklists}`);
            }
            // Comments count
            const commentCount = card._count?.comments || 0;
            if (commentCount > 0) {
                lines.push(`   Comments: ${commentCount}`);
            }
            lines.push('');
        }
    }
    // Summary
    lines.push('---');
    const source = useRestApi
        ? `Source: REST API (${API_URL})`
        : 'Source: local database';
    lines.push(`Summary: ${totalCards} active cards across ` +
        `${board.columns.length} columns.` +
        (blockedCount > 0
            ? ` ${blockedCount} blocked.`
            : '') +
        (overdueCount > 0
            ? ` ${overdueCount} overdue.`
            : '') +
        ` | ${source}`);
    return lines.join('\n');
}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function formatCardText(card) {
    const lines = [];
    lines.push(`# ${card.title}`);
    lines.push('');
    if (card.column?.board?.name)
        lines.push(`**Board:** ${card.column.board.name}`);
    if (card.column?.name)
        lines.push(`**Column:** ${card.column.name}` +
            ` (${card.column.status})`);
    lines.push(`**Priority:** ${card.priority}`);
    if (card.createdAt)
        lines.push(`**Created:** ${formatDate(card.createdAt)}`);
    if (card.dueDate)
        lines.push(`**Due:** ${formatDate(card.dueDate)}`);
    lines.push(`**Assignees:** ` +
        `${getAssigneeNames(card.assignees || [])}`);
    const tagNames = (card.tags || [])
        .map((t) => t.tag.name)
        .join(', ');
    if (tagNames)
        lines.push(`**Tags:** ${tagNames}`);
    if (card.isBlocked) {
        lines.push('');
        lines.push(`⛔ **BLOCKED**` +
            `${card.blockedReason ? `: ${card.blockedReason}` : ''}`);
        if (card.blockedByCard) {
            lines.push(`   Blocked by: ${card.blockedByCard.title}` +
                ` (${card.blockedByCard.id})`);
        }
    }
    // Description
    lines.push('');
    lines.push('## Description');
    lines.push('');
    lines.push(card.description
        ? stripHtml(card.description)
        : '_No description_');
    // Checklists
    if (card.checklists?.length > 0) {
        lines.push('');
        lines.push('## Checklists');
        for (const cl of card.checklists) {
            lines.push('');
            const doneItems = cl.items?.filter((item) => item.completed).length || 0;
            lines.push(`### ${cl.title}` +
                ` (${doneItems}/${cl.items?.length || 0})`);
            for (const item of cl.items || []) {
                lines.push(`- [${item.completed ? 'x' : ' '}] ${item.title}`);
            }
        }
    }
    // Links
    if (card.links?.length > 0) {
        lines.push('');
        lines.push('## Linked Entities');
        for (const link of card.links) {
            lines.push(`- ${link.entityType}: ${link.entityId}`);
        }
    }
    // Comments
    if (card.comments?.length > 0) {
        lines.push('');
        lines.push('## Comments (recent)');
        for (const comment of [...card.comments].reverse()) {
            const author = `${comment.author.firstName} ` +
                `${comment.author.lastName}`.trim();
            lines.push('');
            lines.push(`**${author}** (${formatDate(comment.createdAt)}):`);
            lines.push(stripHtml(comment.content));
        }
    }
    // Activity
    if (card.activities?.length > 0) {
        lines.push('');
        lines.push('## Activity (recent)');
        for (const activity of [
            ...card.activities,
        ].reverse()) {
            const author = activity.author
                ? `${activity.author.firstName} ` +
                    `${activity.author.lastName}`.trim()
                : 'System';
            lines.push(`- ${formatDate(activity.createdAt)}` +
                ` | ${author} | ${activity.action}`);
        }
    }
    return lines.join('\n');
}
// ─── MCP Server ──────────────────────────────────────────────────────────────
const server = new McpServer({
    name: 'board',
    version: '1.0.0',
});
server.tool('get_board_tasks', 'Get current board state: columns, cards, priorities,' +
    ' assignees, due dates. Use at the start of planning.', { boardId: z.string().optional() }, async ({ boardId }) => {
    const id = boardId || DEFAULT_BOARD_ID;
    if (!id) {
        return {
            content: [
                {
                    type: 'text',
                    text: 'No board ID provided.' +
                        ' Set MCP_BOARD_ID env variable' +
                        ' or pass boardId parameter.',
                },
            ],
        };
    }
    try {
        const board = useRestApi
            ? await fetchBoardRest(id)
            : await fetchBoardPrisma(id);
        if (!board) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `Board not found: ${id}`,
                    },
                ],
            };
        }
        return {
            content: [
                {
                    type: 'text',
                    text: formatBoardText(board),
                },
            ],
        };
    }
    catch (err) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error fetching board: ` +
                        `${err.message}`,
                },
            ],
        };
    }
});
server.tool('get_card_details', 'Get detailed card info: description, checklists,' +
    ' comments, activity. Use before starting task work.', { cardId: z.string() }, async ({ cardId }) => {
    try {
        const card = useRestApi
            ? await fetchCardRest(cardId)
            : await fetchCardPrisma(cardId);
        if (!card) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `Card not found: ${cardId}`,
                    },
                ],
            };
        }
        return {
            content: [
                {
                    type: 'text',
                    text: formatCardText(card),
                },
            ],
        };
    }
    catch (err) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error fetching card: ` +
                        `${err.message}`,
                },
            ],
        };
    }
});
// ─── REST API helpers for write operations ───────────────────────────────────
function requireRestApi() {
    if (!useRestApi) {
        return ('Write operations require REST API.' +
            ' Set MCP_API_URL and MCP_API_KEY' +
            ' environment variables.');
    }
    return null;
}
async function restPost(urlPath, body) {
    const res = await fetch(`${API_URL}${urlPath}`, {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
    });
    const json = await res.json();
    if (!res.ok) {
        throw new Error(`REST API error ${res.status}: ` +
            `${json.error?.message || JSON.stringify(json)}`);
    }
    return json.data;
}
async function restPatch(urlPath, body) {
    const res = await fetch(`${API_URL}${urlPath}`, {
        method: 'PATCH',
        headers: {
            Authorization: `Bearer ${API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
    });
    const json = await res.json();
    if (!res.ok) {
        throw new Error(`REST API error ${res.status}: ` +
            `${json.error?.message || JSON.stringify(json)}`);
    }
    return json.data;
}
// ─── Write MCP tools ─────────────────────────────────────────────────────────
server.tool('move_card', 'Move card to a different column (change status).' +
    ' Use to update task status.', {
    cardId: z.string().describe('Card ID'),
    targetColumnId: z
        .string()
        .describe('Target column ID'),
}, async ({ cardId, targetColumnId }) => {
    const err = requireRestApi();
    if (err)
        return {
            content: [{ type: 'text', text: err }],
        };
    try {
        const card = await restPost(`/api/v1/boards/cards/${cardId}/move`, { targetColumnId, newOrder: 0 });
        const columnName = card.column?.name || targetColumnId;
        return {
            content: [
                {
                    type: 'text',
                    text: `Card "${card.title}" moved` +
                        ` to column "${columnName}"`,
                },
            ],
        };
    }
    catch (e) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error moving card: ` +
                        `${e.message}`,
                },
            ],
        };
    }
});
server.tool('add_comment', 'Add a comment to a card.' +
    ' Use for notes, questions, status updates.', {
    cardId: z.string().describe('Card ID'),
    content: z.string().describe('Comment text'),
}, async ({ cardId, content }) => {
    const err = requireRestApi();
    if (err)
        return {
            content: [{ type: 'text', text: err }],
        };
    try {
        const comment = await restPost(`/api/v1/boards/cards/${cardId}/comments`, { content });
        const cardTitle = comment.card?.title || cardId;
        return {
            content: [
                {
                    type: 'text',
                    text: `Comment added to card "${cardTitle}"`,
                },
            ],
        };
    }
    catch (e) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error adding comment: ` +
                        `${e.message}`,
                },
            ],
        };
    }
});
server.tool('update_card', 'Update card: title, description, priority,' +
    ' due date, color.', {
    cardId: z.string().describe('Card ID'),
    title: z.string().optional().describe('New title'),
    description: z
        .string()
        .optional()
        .describe('New description (HTML format)'),
    priority: z
        .enum(['URGENT', 'HIGH', 'MEDIUM', 'LOW', 'NONE'])
        .optional()
        .describe('Priority'),
    dueDate: z
        .string()
        .optional()
        .describe('Due date (ISO 8601)'),
    color: z
        .string()
        .nullable()
        .optional()
        .describe('Card color'),
}, async ({ cardId, ...fields }) => {
    const err = requireRestApi();
    if (err)
        return {
            content: [{ type: 'text', text: err }],
        };
    try {
        const updateFields = {};
        for (const [key, value] of Object.entries(fields)) {
            if (value !== undefined)
                updateFields[key] = value;
        }
        if (Object.keys(updateFields).length === 0) {
            return {
                content: [
                    {
                        type: 'text',
                        text: 'No fields to update',
                    },
                ],
            };
        }
        const card = await restPatch(`/api/v1/boards/cards/${cardId}`, updateFields);
        const changedFields = Object.keys(updateFields).join(', ');
        return {
            content: [
                {
                    type: 'text',
                    text: `Card "${card.title}" updated: ` +
                        `${changedFields}`,
                },
            ],
        };
    }
    catch (e) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error updating card: ` +
                        `${e.message}`,
                },
            ],
        };
    }
});
server.tool('create_card', 'Create a new card on the board.' +
    ' Specify column, title, optional description' +
    ' and priority.', {
    columnId: z
        .string()
        .describe('Column ID to add the card to'),
    title: z.string().describe('Card title'),
    description: z
        .string()
        .optional()
        .describe('Description (HTML format)'),
    priority: z
        .enum(['URGENT', 'HIGH', 'MEDIUM', 'LOW', 'NONE'])
        .optional()
        .describe('Priority'),
}, async ({ columnId, title, description, priority }) => {
    const err = requireRestApi();
    if (err)
        return {
            content: [{ type: 'text', text: err }],
        };
    try {
        const body = {
            columnId,
            title,
        };
        if (description)
            body.description = description;
        if (priority)
            body.priority = priority;
        const card = await restPost('/api/v1/boards/cards', body);
        const columnName = card.column?.name || columnId;
        return {
            content: [
                {
                    type: 'text',
                    text: `Card "${card.title}" created` +
                        ` in column "${columnName}"`,
                },
            ],
        };
    }
    catch (e) {
        return {
            content: [
                {
                    type: 'text',
                    text: `Error creating card: ` +
                        `${e.message}`,
                },
            ],
        };
    }
});
// ─── Start ───────────────────────────────────────────────────────────────────
async function main() {
    const mode = useRestApi
        ? `REST API (${API_URL})`
        : 'Prisma (local DB)';
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error(`[board] MCP server started — ${mode}`);
}
main().catch((err) => {
    console.error('[board] Failed to start:', err);
    process.exit(1);
});
process.on('SIGINT', async () => {
    if (prisma)
        await prisma.$disconnect();
    process.exit(0);
});
process.on('SIGTERM', async () => {
    if (prisma)
        await prisma.$disconnect();
    process.exit(0);
});
//# sourceMappingURL=board-server.js.map