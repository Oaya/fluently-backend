class HomeworkAiPlaceholder
  def initialize(language:, level:, exercise_type:, topics: [], notes: nil)
    @language = language
    @level = level
    @exercise_type = exercise_type
    @topics = Array(topics).reject(&:blank?)
    @notes = notes
  end

  def call
    { title: title, instructions: instructions }
  end

  private

  def title
    topic = @topics.first || "General practice"
    "#{@exercise_type}: #{topic} (#{@language} · #{@level})"
  end

  def instructions
    lines = [
      "Exercise type: #{@exercise_type}",
      "Level: #{@level}",
      ("Topic(s): #{@topics.join(', ')}" if @topics.any?),
      "",
      placeholder_body,
      ("" if @notes.present?),
      ("Notes: #{@notes}" if @notes.present?)
    ]

    lines.compact.join("\n")
  end

  def placeholder_body
    "This is placeholder homework content generated without an AI model. " \
    "Replace HomeworkAiPlaceholder with a real model call to produce tailored " \
    "#{@exercise_type.downcase} content for a #{@level} #{@language} student."
  end
end
