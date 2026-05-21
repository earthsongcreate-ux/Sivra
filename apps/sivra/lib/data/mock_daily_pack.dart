import '../models/drill_item.dart';

class MockDailyPack {
  static const items = <DrillItem>[
    DrillItem(
      id: 'b1',
      type: DrillItemType.briefing,
      prompt: 'A major model capability shift and what it changes for product teams.',
      answer: 'Focus on workflows, evals, and distribution. Model gains compress feature timelines.',
      explanation: 'Treat models as commodities. Build defensible workflows, data loops, and trust.',
      source: DrillItemSource(
        title: 'Model capabilities update',
        publisher: 'Trusted publication',
        dateLabel: 'Today',
        url: 'https://example.com',
        snippet: 'Summary of the capability shift and implications for builders.',
      ),
    ),
    DrillItem(
      id: 'b2',
      type: DrillItemType.briefing,
      prompt: 'A notable AI platform move (API/pricing/policy) and what it implies for startups.',
      answer: 'Assume pricing/policies change. Design provider-agnostic routing and caching.',
      explanation: 'Avoid lock-in. Own prompts, evals, and routing in your backend.',
      source: DrillItemSource(
        title: 'Platform policy change',
        publisher: 'Industry source',
        dateLabel: 'Today',
        url: 'https://example.com',
        snippet: 'Pricing or policy changes that affect cost and reliability.',
      ),
    ),
    DrillItem(
      id: 'd1',
      type: DrillItemType.concept,
      prompt: 'Model vs product moat: what can’t be copied in 90 days?',
      answer: 'Workflow integration, distribution, proprietary data loops, and trust.',
      explanation: 'If a competitor can replicate it quickly, it is not a moat.',
    ),
    DrillItem(
      id: 'd2',
      type: DrillItemType.decision,
      prompt: 'You have one engineer-week: ship evals, ship features, or reduce latency—pick and justify.',
      answer: 'Evals first for safety and velocity, then latency; features follow durable quality.',
      explanation: 'Evals prevent regressions and make iteration safer and faster.',
    ),
    DrillItem(
      id: 'd3',
      type: DrillItemType.scenario,
      prompt: 'A customer asks: “Are we training on our data?” — best answer?',
      answer: 'No training by default; clarify retention, access controls, and what is stored.',
      explanation: 'Be precise and calm. Avoid vague assurances; explain your data handling policy.',
    ),
    DrillItem(
      id: 'd4',
      type: DrillItemType.concept,
      prompt: 'Why “context length” isn’t the same as “memory.”',
      answer: 'Context is temporary input; memory is persisted, structured recall across sessions.',
      explanation: 'Long context helps, but without persistence and retrieval it is not memory.',
    ),
    DrillItem(
      id: 'd5',
      type: DrillItemType.articulation,
      prompt: 'Explain your AI feature to a skeptical CFO in 5 sentences.',
      explanation: 'Write it clearly. Avoid jargon. Lead with ROI, risk controls, and costs.',
    ),
    DrillItem(
      id: 'd6',
      type: DrillItemType.review,
      prompt: 'Define hallucination vs retrieval error.',
      answer: 'Hallucination: fabricated content. Retrieval error: wrong/irrelevant source returned.',
      explanation: 'Different failure modes, different fixes: prompting/evals vs indexing/retrieval tuning.',
    ),
  ];
}

