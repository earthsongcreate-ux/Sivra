import '../models/drill_item.dart';

class MockDailyPack {
  static List<DrillItem> forFocus(
    List<String> focusAreas, {
    List<DrillItemType> weakDrillTypes = const <DrillItemType>[],
  }) {
    final primary = focusAreas.isEmpty ? 'Product strategy' : focusAreas.first;
    final lens = _focusLens(primary);
    final practiceLens = _practiceLens(weakDrillTypes);

    return <DrillItem>[
      DrillItem(
        id: 'b1',
        type: DrillItemType.briefing,
        prompt:
            'A major model capability shift and what it changes for ${lens.team}.',
        answer: lens.briefingAnswer,
        explanation: lens.briefingExplanation,
        source: const DrillItemSource(
          title: 'OpenAI news',
          publisher: 'OpenAI',
          dateLabel: 'Today',
          url: 'https://openai.com/news/',
          snippet:
              'Summary of the capability shift and implications for builders.',
        ),
      ),
      DrillItem(
        id: 'b2',
        type: DrillItemType.briefing,
        prompt:
            'A notable AI platform move and what it implies for ${lens.operator}.',
        answer:
            'Assume pricing, policy, and model quality will keep changing. Design routing and evaluation habits early.',
        explanation: lens.platformExplanation,
        source: const DrillItemSource(
          title: 'OpenAI platform docs',
          publisher: 'OpenAI Platform',
          dateLabel: 'Today',
          url: 'https://platform.openai.com/docs/',
          snippet:
              'Pricing or policy changes that affect cost and reliability.',
        ),
      ),
      ..._drillsFor(lens, practiceLens),
    ];
  }

  static final items = forFocus(const <String>[]);

  static List<DrillItem> _drillsFor(
    _FocusLens lens,
    _PracticeLens practiceLens,
  ) {
    return <DrillItem>[
      DrillItem(
        id: 'd1',
        type: DrillItemType.concept,
        prompt: practiceLens.conceptPrompt ?? lens.moatPrompt,
        answer: lens.moatAnswer,
        explanation:
            'If a competitor can replicate it quickly, it is not a durable advantage.',
      ),
      DrillItem(
        id: 'd2',
        type: DrillItemType.decision,
        prompt: practiceLens.decisionPrompt ?? lens.decisionPrompt,
        answer: lens.decisionAnswer,
        explanation:
            'Choose the work that reduces repeated uncertainty before chasing surface polish.',
      ),
      const DrillItem(
        id: 'd3',
        type: DrillItemType.scenario,
        prompt:
            'A customer asks: “Are we training on our data?” — best answer?',
        answer:
            'No training by default; clarify retention, access controls, and what is stored.',
        explanation:
            'Be precise and calm. Avoid vague assurances; explain your data handling policy.',
      ),
      const DrillItem(
        id: 'd4',
        type: DrillItemType.concept,
        prompt: 'Why “context length” isn’t the same as “memory.”',
        answer:
            'Context is temporary input; memory is persisted, structured recall across sessions.',
        explanation:
            'Long context helps, but without persistence and retrieval it is not memory.',
      ),
      DrillItem(
        id: 'd5',
        type: DrillItemType.articulation,
        prompt: practiceLens.articulationPrompt ?? lens.articulationPrompt,
        explanation: lens.articulationHint,
      ),
      const DrillItem(
        id: 'd6',
        type: DrillItemType.review,
        prompt: 'Define hallucination vs retrieval error.',
        answer:
            'Hallucination: fabricated content. Retrieval error: wrong/irrelevant source returned.',
        explanation:
            'Different failure modes, different fixes: prompting/evals vs indexing/retrieval tuning.',
      ),
    ];
  }

  static _FocusLens _focusLens(String focus) {
    switch (focus) {
      case 'GTM & sales':
        return const _FocusLens(
          team: 'go-to-market teams',
          operator: 'sales and customer-facing teams',
          briefingAnswer:
              'Package capability gains as measurable buyer outcomes, not model novelty.',
          briefingExplanation:
              'Position AI around speed, risk reduction, and proof points a buyer can validate.',
          platformExplanation:
              'Keep claims tied to outcomes you can preserve even if a model vendor changes.',
          moatPrompt: 'AI sales moat: what can’t be copied in 90 days?',
          moatAnswer:
              'Distribution, customer context, proof from usage, and trusted implementation patterns.',
          decisionPrompt:
              'You have one GTM week: build demos, improve qualification, or write proof points — pick and justify.',
          decisionAnswer:
              'Proof points first; they sharpen demos, qualification, and buyer confidence.',
          articulationPrompt:
              'Explain your AI feature to a skeptical CFO in 5 sentences.',
          articulationHint:
              'Write it clearly. Avoid jargon. Lead with ROI, risk controls, and costs.',
        );
      case 'Hiring & team':
        return const _FocusLens(
          team: 'hiring and team design',
          operator: 'founders building AI-capable teams',
          briefingAnswer:
              'Capability shifts change role design: fewer handoffs, more judgment, stronger evaluation habits.',
          briefingExplanation:
              'Hire for workflow ownership and taste, not only tool familiarity.',
          platformExplanation:
              'Team process should survive vendor changes by keeping prompts, evals, and decisions explicit.',
          moatPrompt: 'AI team moat: what can’t be copied in 90 days?',
          moatAnswer:
              'Shared judgment, operating cadence, proprietary workflows, and accumulated evaluation data.',
          decisionPrompt:
              'You have one team week: train everyone, hire a specialist, or document workflows — pick and justify.',
          decisionAnswer:
              'Document workflows first; it reveals gaps and makes training or hiring more precise.',
          articulationPrompt:
              'Write the role scorecard for an AI-fluent operator in 5 sentences.',
          articulationHint:
              'Name outcomes, judgment expectations, tool habits, and what great work looks like.',
        );
      case 'Infra & costs':
        return const _FocusLens(
          team: 'AI infrastructure and cost control',
          operator: 'teams managing AI reliability and spend',
          briefingAnswer:
              'Capability gains matter only when latency, routing, and evaluation keep unit economics healthy.',
          briefingExplanation:
              'Model choice is an operating decision: quality, cost, latency, and risk move together.',
          platformExplanation:
              'Track vendor changes with routing, caching, evals, and clear rollback options.',
          moatPrompt: 'AI infra moat: what can’t be copied in 90 days?',
          moatAnswer:
              'Reliable evals, cost telemetry, tuned retrieval, fallback paths, and production learning loops.',
          decisionPrompt:
              'You have one infra week: ship evals, reduce latency, or cut token cost — pick and justify.',
          decisionAnswer:
              'Evals first; they make latency and cost changes safer to ship.',
          articulationPrompt:
              'Explain your AI cost-control plan to a skeptical CFO in 5 sentences.',
          articulationHint:
              'Lead with unit cost, risk controls, monitoring, and what triggers a rollback.',
        );
      default:
        return const _FocusLens(
          team: 'product teams',
          operator: 'startups',
          briefingAnswer:
              'Focus on workflows, evals, and distribution. Model gains compress feature timelines.',
          briefingExplanation:
              'Treat models as commodities. Build defensible workflows, data loops, and trust.',
          platformExplanation:
              'Avoid lock-in. Own prompts, evals, and routing in your backend.',
          moatPrompt: 'Model vs product moat: what can’t be copied in 90 days?',
          moatAnswer:
              'Workflow integration, distribution, proprietary data loops, and trust.',
          decisionPrompt:
              'You have one engineer-week: ship evals, ship features, or reduce latency — pick and justify.',
          decisionAnswer:
              'Evals first for safety and velocity, then latency; features follow durable quality.',
          articulationPrompt:
              'Explain your AI feature to a skeptical CFO in 5 sentences.',
          articulationHint:
              'Write it clearly. Avoid jargon. Lead with ROI, risk controls, and costs.',
        );
    }
  }

  static _PracticeLens _practiceLens(List<DrillItemType> weakDrillTypes) {
    if (weakDrillTypes.contains(DrillItemType.articulation)) {
      return const _PracticeLens(
        articulationPrompt:
            'Rewrite your AI value proposition for a skeptical executive in 5 sentences.',
      );
    }

    if (weakDrillTypes.contains(DrillItemType.decision)) {
      return const _PracticeLens(
        decisionPrompt:
            'Pick the safest next AI investment and reject two tempting alternatives.',
      );
    }

    if (weakDrillTypes.contains(DrillItemType.concept)) {
      return const _PracticeLens(
        conceptPrompt:
            'Explain the concept that most affects your AI strategy this week.',
      );
    }

    return const _PracticeLens();
  }
}

class _PracticeLens {
  final String? conceptPrompt;
  final String? decisionPrompt;
  final String? articulationPrompt;

  const _PracticeLens({
    this.conceptPrompt,
    this.decisionPrompt,
    this.articulationPrompt,
  });
}

class _FocusLens {
  final String team;
  final String operator;
  final String briefingAnswer;
  final String briefingExplanation;
  final String platformExplanation;
  final String moatPrompt;
  final String moatAnswer;
  final String decisionPrompt;
  final String decisionAnswer;
  final String articulationPrompt;
  final String articulationHint;

  const _FocusLens({
    required this.team,
    required this.operator,
    required this.briefingAnswer,
    required this.briefingExplanation,
    required this.platformExplanation,
    required this.moatPrompt,
    required this.moatAnswer,
    required this.decisionPrompt,
    required this.decisionAnswer,
    required this.articulationPrompt,
    required this.articulationHint,
  });
}
