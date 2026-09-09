import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

// Collections skip files prefixed with `_` (used for `_example.md` frontmatter samples
// and the `_v1/` archive of the first-pass MDX pages).
const skipUnderscored = (base: string) =>
  glob({ pattern: ['**/[^_]*.md', '**/[^_]*.mdx'], base });

/** One file per skill per locale: src/content/skills/{en,vi}/<name>.md (build spec 4 §6).
 *  The same glob still matches a flat `<name>.md` left over from pass 1, which
 *  src/lib/skills.ts reads as English — so the catalog keeps working while the writers
 *  are still moving files. Every field except `title` is optional: a half-written
 *  frontmatter must not fail the build. */
const skills = defineCollection({
  loader: skipUnderscored('./src/content/skills'),
  schema: z.object({
    title: z.string(),
    oneLiner: z.string().default(''),
    lang: z.enum(['vi', 'en']).optional(),
    group: z
      .enum(['entry', 'main-flow', 'shaping', 'gate', 'brownfield', 'upkeep', 'adapter'])
      .optional(),
    order: z.number().default(50),
    runtimes: z.array(z.enum(['claude', 'codex', 'opencode'])).default([]),
    source: z.string().optional(),
    rented: z.boolean().default(false),
    diagram: z.string().optional(),
    updated: z.coerce.date().optional(),
  }),
});

const dictionary = defineCollection({
  loader: skipUnderscored('./src/content/dictionary'),
  schema: z.object({
    term: z.string(),
    oneLiner: z.string(),
    order: z.number(),
    related: z.array(z.string()).default([]),
    diagram: z.string().optional(),
    updated: z.coerce.date(),
  }),
});

const essays = defineCollection({
  loader: skipUnderscored('./src/content/essays'),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    date: z.coerce.date(),
    readingMinutes: z.number(),
  }),
});

// One entry per locale/page: src/content/pages/{vi,en}/<slug>.md — home, failures,
// evidence, adopt, plus structure, why, tech-stack and hooks (build spec 4 §6).
// Ids are `vi/home`, `en/structure`, … Prose only; every AST id, ledger row, commit and
// command is injected by the layout from src/data/*.json.
const pages = defineCollection({
  loader: glob({ pattern: '{vi,en}/[^_]*.md', base: './src/content/pages' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    acts: z
      .array(
        z.object({
          id: z.string(),
          eyebrow: z.string().optional(),
          headline: z.string().optional(),
        }),
      )
      .optional(),
  }),
});

/** Landing captions, one file per locale: src/content/landing/{vi,en}.yaml (build spec 4
 *  §4 and §6). Every field is optional so a half-written file still builds;
 *  src/lib/landing.ts merges what lands over a placeholder default and the page shows
 *  the gap instead of failing the build. */
const caption = z.object({ headline: z.string().optional(), sub: z.string().optional() });
/** One pane of literal commands inside an explain section. A section may carry one or
 *  several; the single-object form is the older spelling and still validates. */
const pane = z.object({ label: z.string().optional(), lines: z.array(z.string()) });
const landing = defineCollection({
  loader: glob({ pattern: '[^_]*.{yaml,yml}', base: './src/content/landing' }),
  schema: z.object({
    hero: z
      .object({
        eyebrow: z.string().optional(),
        headline: z.string().optional(),
        sub: z.string().optional(),
        primary: z.string().optional(),
        secondary: z.string().optional(),
      })
      .optional(),
    /** Home v2 §Section 1: two columns of prose, no picture. */
    why: z
      .object({
        headline: z.string().optional(),
        p1: z.string().optional(),
        p2: z.string().optional(),
        more: z.string().optional(),
      })
      .optional(),
    /** Home v2 §Section 2: six cards, in the writer's order. `diagram` is a slug under
     *  src/assets/diagrams and `crop` the node ids the card's thumbnail is cut down to;
     *  a card with neither renders copy only. */
    features: z
      .array(
        z.object({
          id: z.string(),
          title: z.string().optional(),
          body: z.string().optional(),
          diagram: z.string().optional(),
          crop: z.array(z.string()).optional(),
          href: z.string().optional(),
        }),
      )
      .optional(),
    /** Home explain spec §A-§E: the five sections that say what an agent, a message,
     *  a role, the tracker and the method actually are. Every field is optional and
     *  the keys are shared, so a section renders whichever of them the writer filled:
     *  `commands` is a code pane, `items` is a list of rows, `paragraphs` is prose. */
    explain: z
      .record(
        z.string(),
        z.object({
          eyebrow: z.string().optional(),
          headline: z.string().optional(),
          paragraphs: z.array(z.string()).optional(),
          commands: z.union([pane, z.array(pane)]).optional(),
          items: z
            .array(
              z.object({
                id: z.string().optional(),
                title: z.string().optional(),
                tag: z.string().optional(),
                session: z.string().optional(),
                body: z.string().optional(),
                /** Verbatim English, quoted rather than translated. */
                text: z.string().optional(),
                href: z.string().optional(),
              }),
            )
            .optional(),
          more: z.object({ label: z.string(), href: z.string() }).optional(),
          models: z.object({ label: z.string(), intro: z.string(), note: z.string() }).optional(),
        }),
      )
      .optional(),
    /** Home v2 §Section 4. `fits` / `notYet` avoid the YAML keys `yes` and `no`. */
    fit: z
      .object({
        headline: z.string().optional(),
        body: z.string().optional(),
        fitsLabel: z.string().optional(),
        notYetLabel: z.string().optional(),
        fits: z.array(z.string()).optional(),
        notYet: z.array(z.string()).optional(),
      })
      .optional(),
    /** Home v2 §Section 5. The commands themselves come from src/data/adopt.json. */
    adopt: z
      .object({
        headline: z.string().optional(),
        reqTitle: z.string().optional(),
        reqHeadline: z.string().optional(),
        requirements: z
          .array(
            z.object({
              name: z.string(),
              tag: z.string().optional(),
              role: z.string().optional(),
              href: z.string().optional(),
            }),
          )
          .optional(),
      })
      .optional(),
    /** Photographs of the running system that the owner has not sent yet. Keyed by the
     *  slug HomeBody asks for; `src` is a path under site/public and turns the dashed
     *  placeholder into the real picture (home order spec §3). */
    shots: z
      .record(
        z.string(),
        z.object({ caption: z.string().optional(), src: z.string().optional() }),
      )
      .optional(),
    sections: z
      .object({
        structure: caption.optional(),
        roles: caption.optional(),
        /** The whole team in one picture, between the roles and the messaging. */
        team: caption
          .extend({
            pointsLabel: z.string().optional(),
            points: z.array(z.object({ title: z.string(), body: z.string() })).optional(),
          })
          .optional(),
        lifecycle: caption.optional(),
        tracker: caption.optional(),
        skills: caption.extend({ cta: z.string().optional() }).optional(),
        hooks: caption.optional(),
        why: caption.optional(),
        stack: caption.optional(),
        // Kept so a pass-3 YAML still validates; no longer rendered on the landing.
        arm: caption.optional(),
        evidence: caption.extend({ cta: z.string().optional() }).optional(),
        limit: caption.optional(),
      })
      .optional(),
    stages: z
      .object({
        claim: z.string().optional(),
        brief: z.string().optional(),
        build: z.string().optional(),
        'code-review': z.string().optional(),
        simplify: z.string().optional(),
        arm: z.string().optional(),
        merge: z.string().optional(),
      })
      .optional(),
    roleCards: z
      .object({
        thomas: z.string().optional(),
        shaper: z.string().optional(),
        builder: z.string().optional(),
        rin: z.string().optional(),
        qa: z.string().optional(),
      })
      .optional(),
    /** Landing cards for sections 7, 8 and 9. `id`/`slug` is the anchor on the
     *  destination page and must match src/lib/anchors.ts; everything else is copy. */
    hooksCards: z
      .array(
        z.object({
          id: z.string(),
          title: z.string().optional(),
          when: z.string().optional(),
          does: z.string().optional(),
        }),
      )
      .optional(),
    whyCards: z
      .array(
        z.object({
          slug: z.string(),
          question: z.string().optional(),
          oneLine: z.string().optional(),
        }),
      )
      .optional(),
    stackItems: z
      .array(
        z.object({
          slug: z.string(),
          name: z.string().optional(),
          oneLine: z.string().optional(),
        }),
      )
      .optional(),
  }),
});

/** One page per role per locale: src/content/roles/{vi,en}/<id>.md (landing spec §3).
 *  Body carries `## does`, `## may`, `## may-not`; src/lib/pages.ts splits them. */
const roles = defineCollection({
  loader: glob({ pattern: '{vi,en}/[^_]*.md', base: './src/content/roles' }),
  schema: z.object({
    title: z.string(),
    tagline: z.string().optional(),
    sessionTag: z.string().optional(),
  }),
});

export const collections = { skills, dictionary, essays, pages, landing, roles };
