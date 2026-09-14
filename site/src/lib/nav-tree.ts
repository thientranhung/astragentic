import { HOOKS, STACK, TIPS, WHY } from './anchors';
import { getSkillGroups, GROUPS, type GroupId } from './skills';
import { ROLE_IDS, ROLE_META, roleHref, type RoleId } from './roles';
import { ROUTES, UI, type Lang } from './site';

/** The site tree the Read-mode sidebar draws (design spec 5 §2). It is generated, not
 *  typed out: the roles come from ROLE_IDS, the skills from the collections by group,
 *  and hooks / why / tech-stack from the same anchor tables the pages themselves use.
 *  A skill that lands in the content directory therefore appears in the sidebar the
 *  same build, and an anchor cannot exist on a page but be missing here. */

export interface NavLeaf {
  label: string;
  href: string;
  /** Set when the leaf is an anchor on a page: the client script highlights it from
   *  the scroll position, because every anchor on a page shares one pathname. */
  anchor?: string;
  role?: RoleId;
  group?: GroupId;
}

export interface NavGroup {
  id: GroupId;
  label: string;
  items: NavLeaf[];
}

export interface NavSection {
  id: string;
  label: string;
  /** A section with no children is a plain link. */
  href?: string;
  items?: NavLeaf[];
  /** Only /skills has a second level: seven groups, each listing its skills. */
  groups?: NavGroup[];
}

const anchors = (base: string, rows: { id: string; label: string }[]): NavLeaf[] =>
  rows.map((row) => ({ label: row.label, href: `${base}#${row.id}`, anchor: row.id }));

/** Same order as the top nav (site.ts NAV): why, structure, roles, skills, hooks, stack,
 *  then the two pages the top nav leaves out, then install. One order, two menus. */
export async function getNavTree(lang: Lang): Promise<NavSection[]> {
  const skillGroups = await getSkillGroups(lang);

  return [
    {
      id: 'why',
      label: UI.sideWhy[lang],
      href: ROUTES.why[lang],
      items: anchors(
        ROUTES.why[lang],
        WHY.map((why) => ({ id: why.id, label: why.question[lang] })),
      ),
    },
    { id: 'structure', label: UI.sideStructure[lang], href: ROUTES.structure[lang] },
    {
      id: 'roles',
      label: UI.sideRoles[lang],
      items: ROLE_IDS.map((id) => ({
        label: ROLE_META[id].label,
        href: roleHref(lang, id),
        role: id,
      })),
    },
    {
      id: 'skills',
      label: UI.sideSkills[lang],
      href: ROUTES.skills[lang],
      groups: skillGroups.map((group) => ({
        id: group.id,
        label: GROUPS[group.id].title[lang],
        items: group.skills.map((skill) => ({
          label: skill.name,
          href: skill.href,
          group: group.id,
        })),
      })),
    },
    {
      id: 'hooks',
      label: UI.sideHooks[lang],
      href: ROUTES.hooks[lang],
      items: anchors(
        ROUTES.hooks[lang],
        HOOKS.map((hook) => ({
          id: hook.id,
          // Every hook script lives under `scripts/`; printing the directory four times
          // in a 240px rail costs a line each and says nothing.
          label: hook.script?.replace(/^scripts\//, '') ?? hook.event,
        })),
      ),
    },
    {
      id: 'stack',
      label: UI.sideStack[lang],
      href: ROUTES.stack[lang],
      items: anchors(
        ROUTES.stack[lang],
        STACK.map((item) => ({ id: item.id, label: item.name })),
      ),
    },
    {
      id: 'tips',
      label: UI.sideTips[lang],
      href: ROUTES.tips[lang],
      /* The closing section is not a technique, so it is not in TIPS — but it is a
         heading a reader can land on, and a rail that lists five of six sections is a
         rail that is quietly wrong. */
      items: anchors(ROUTES.tips[lang], [
        ...TIPS.map((item) => ({ id: item.id, label: item.name[lang] })),
        { id: 'one-shape', label: lang === 'vi' ? 'Một hình dạng chung' : 'One shape' },
      ]),
    },
    { id: 'failures', label: UI.sideFailures[lang], href: ROUTES.failures[lang] },
    {
      id: 'customize',
      label: UI.sideCustomize[lang],
      href: ROUTES.customize[lang],
      /* Five sections now, where this used to be an installer and a list of brownfield
         skills. A plain link would hide four of them. */
      items: anchors(ROUTES.customize[lang], [
        { id: 'install', label: UI.quickstart[lang] },
        { id: 'customize', label: UI.customizeHeads.customize[lang] },
        { id: 'agent-customize', label: UI.customizeHeads['agent-customize'][lang] },
        { id: 'self-repair', label: UI.customizeHeads['self-repair'][lang] },
        { id: 'brownfield', label: UI.brownfield[lang] },
      ]),
    },
  ];
}

/** Trailing slashes differ between `astro dev` and the built output; compare without. */
export const samePath = (a: string, b: string): boolean =>
  a.replace(/\/+$/, '').split('#')[0] === b.replace(/\/+$/, '').split('#')[0];

/** True when this section owns the page being read — it opens on arrival. */
export function sectionHoldsPath(section: NavSection, path: string): boolean {
  if (section.href && samePath(section.href, path)) return true;
  if (section.items?.some((leaf) => samePath(leaf.href, path))) return true;
  return Boolean(
    section.groups?.some((group) => group.items.some((leaf) => samePath(leaf.href, path))),
  );
}
