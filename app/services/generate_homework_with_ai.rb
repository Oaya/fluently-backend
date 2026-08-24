class GenerateHomeworkWithAi
  def initialize(language:, level:, exercise_type:, topics: [], notes: nil)
    @language = language
    @level = level
    @exercise_type = exercise_type
    @topics = Array(topics).reject(&:blank?)
    @notes = notes
  end

  def call
    client = OpenAI::Client.new(access_token: ENV["OPEN_API_SECRET_KEY"])

    response = client.chat(
      parameters: {
        model: ENV["OPEN_API_MODEL"],
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ],
        max_tokens: 1200,
        temperature: 0.7
      }
    )

    raw = response.dig("choices", 0, "message", "content")
    parsed = JSON.parse(raw)

    {
      title: parsed["title"].presence || fallback_title,
      instructions: parsed["instructions"].presence || ""
    }
  rescue => e
    Rails.logger.error("[GenerateHomeworkWithAi] #{e.class}: #{e.message}")
    raise
  end

  private

  def system_prompt
    <<~PROMPT
      You are an experienced language teacher creating homework assignments.
      Write every exercise and instruction bilingually: pair each target-language
      (#{@language}) line with its English translation, so a student can check their
      understanding without a dictionary.
      #{reading_note}
      #{japanese_note if japanese?}
      This formatting is MANDATORY for every single #{@language} sentence or phrase that
      appears anywhere in the response — including the title, section headers, and directions
      to the student (e.g. "please fill in the blanks", "use the example as a guide"), not only
      example sentences or answer content. There is no #{@language} text anywhere in the output
      that is exempt from this. Never skip the readings and never collapse the lines into one —
      each part always goes on its own line.
      Always respond with valid JSON containing exactly two keys:
        - "title": a homework title (max 300 characters), as a JSON string containing real
          newline characters. It must follow the exact same multi-line formatting rules as the
          instructions below — it is NOT exempt and is NOT a single line of plain text. For
          example, if #{@language} is Japanese, the "title" value itself must look like:
            "日本語を勉強する\nにほんごをべんきょうする\nnihongo wo benkyou suru\nstudy Japanese"
          (four lines, in that order). A one-line title, or a title with the readings squeezed
          into parentheses instead of their own lines, is WRONG.
        - "instructions": the full homework instructions for the student (plain text, well-structured)
      Do not include any text outside the JSON object.
    PROMPT
  end

  def user_prompt
    parts = [
      "Create a #{@exercise_type.downcase} homework assignment.",
      "Target language: #{@language}",
      "Student level: #{@level} (CEFR)",
      (@topics.any? ? "Topic(s): #{@topics.join(', ')}" : nil),
      (@notes.present? ? "Teacher notes: #{@notes}" : nil),
      "",
      "Write clear, student-facing instructions, formatting every #{@language} sentence or phrase",
      "exactly as instructed in the system message (target language / readings / English, each on",
      "its own line) — including inside the title.",
      "Include examples where helpful.",
      "Match the difficulty to the #{@level} CEFR level.",
      reading_note,
      (japanese_note if japanese?)
    ]
    parts.compact.join("\n")
  end

  def japanese?
    @language.to_s.downcase.include?("japanese")
  end

  def reading_note
    <<~NOTE.strip
      If #{@language} is not written in the Latin alphabet (e.g. Japanese, Chinese, Korean,
      Russian, Arabic, Thai, Hindi, Greek, Hebrew), add a romanized reading for every
      #{@language} sentence or phrase, using that language's standard romanization system
      (romaji for Japanese, pinyin for Chinese, Revised Romanization for Korean, standard
      transliteration for Russian/Arabic/Hebrew/Greek/etc.), so the student can read it aloud
      without knowing the native script. Put the target-language line, the romanized reading,
      and the English translation each on its own separate line, in this order:
        #{@language} text
        Romanized reading
        English translation
      If #{@language} already uses the Latin alphabet, skip the romanized line — just the
      target-language line and the English translation, each on its own line, is enough.
    NOTE
  end

  def japanese_note
    <<~NOTE.strip
      For Japanese specifically, use kanji appropriate to the student's level (#{@level}):
      favor kana and only the most common, level-appropriate kanji for beginner levels
      (A1-A2), introducing more kanji as the level rises (B1+). Because kanji is used, add a
      full hiragana reading (yomi) of the line as well as the romaji reading. Put each part on
      its own separate line, in this exact order, for every Japanese sentence or phrase:
        Japanese text (with kanji as appropriate for the level)
        Hiragana reading of the full line
        Romaji reading of the full line
        English translation
      Example (a vocabulary line):
        日本語を勉強する
        にほんごをべんきょうする
        nihongo wo benkyou suru
        study Japanese
      Example (a direction line — directions get the exact same treatment, never just English):
        次の文章の空いている部分に適切な言葉を入れてください。
        つぎのぶんしょうのあいているぶぶんにてきせつなことばをいれてください。
        tsugi no bunshou no aiteiru bubun ni tekisetsu na kotoba wo irete kudasai.
        Fill in the appropriate words in the blank spaces in the following sentences.
    NOTE
  end

  def fallback_title
    topic = @topics.first || "General practice"
    "#{@exercise_type}: #{topic} (#{@language} · #{@level})"
  end
end
