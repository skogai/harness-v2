## Design Context

### Users
Engineering leads overseeing human and AI work across task boards, specifications, dependency graphs, execution traces, and cost data. They need to understand project state quickly, identify blockers and exceptions, verify proof of work, and intervene without reconstructing context from raw logs or external tools.

### Brand Personality
Simple, effective, and context-efficient. The product voice should be direct, precise, and operational. It should create confidence through legibility and evidence rather than decoration or novelty.

### Aesthetic Direction
Use a dark-only, technical operations interface built around the existing Geist and Geist Mono typefaces, compact shadcn/Radix primitives, restrained neutral surfaces, and semantic status colors. Favor clear hierarchy, dense but scannable layouts, concise labels, and progressive disclosure for details. Preserve the existing small-radius geometry and use motion only to communicate state or causality. Avoid decorative gradients, oversized marketing treatments, playful visual language, and color that does not encode meaning.

No formal accessibility target has been specified. Maintain strong dark-theme contrast, visible keyboard focus, non-color status cues, readable type at compact sizes, and reduced-motion compatibility as baseline requirements.

### Design Principles
1. **Make state obvious.** Surface status, ownership, dependencies, cost, blockers, and proof where leads make decisions.
2. **Spend context carefully.** Lead with the smallest useful summary, then reveal traces, metadata, and evidence on demand.
3. **Optimize for scanning.** Use consistent hierarchy, alignment, semantic color, and compact typography so exceptions stand out immediately.
4. **Keep control human and defaults useful.** Present strong suggested actions and assignments while making overrides clear and low-friction.
5. **Prefer evidence over decoration.** Every visual element should clarify work, causality, risk, or outcome.
