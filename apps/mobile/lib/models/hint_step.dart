class HintStep {
  final int order;
  final String content;
  final String? latex;

  const HintStep({required this.order, required this.content, this.latex});

  Map<String, dynamic> toJson() => {
        'order': order,
        'content': content,
        if (latex != null) 'latex': latex,
      };

  factory HintStep.fromJson(Map<String, dynamic> json) => HintStep(
        order: json['order'] as int,
        content: json['content'] as String,
        latex: json['latex'] as String?,
      );
}
