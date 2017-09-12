require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @toc = File.readlines('data/toc.txt')
end

helpers do
  def chapter_contents(number)
    File.read("data/chp#{number}.txt")
  end

  def each_chapter
    @toc.each.with_index do |title, chapter_index|
      chapter_number = chapter_index + 1
      chapter_contents = chapter_contents(chapter_number)
      yield title, chapter_number, chapter_contents
    end
  end

  def each_paragraph(text)
    text.split("\n\n").each_with_index do |paragraph, index|
      yield paragraph, index
    end
  end

  def in_paragraphs(text)
    result = ''
    each_paragraph(text) do |paragraph, index|
      result += "<p id=para#{index}>#{paragraph}</p>"
    end

    result
  end

  def chapter_results(query)
    results = []

    return results unless query

    each_chapter do |title, number, chapter|
      next unless chapter.include?(query)

      matches = {}
      each_paragraph(chapter) do |paragraph, id|
        matches[id] = highlight(paragraph, query) if paragraph.include?(query)
      end
      results << { title: title, chapter_number: number, paragraphs: matches } unless matches.empty?
    end

    results
  end

  def highlight(full_text, important_text)
    full_text.gsub(important_text, "<strong>#{important_text}</strong>")
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home, layout: :layout # the layout: :layout is default options hash
end

get "/chapters/:number" do
  number = params[:number].to_i # or params['number'].to_i
  chapter_title = @toc[number - 1]

  redirect "/" unless (1..@toc.size).cover? number

  @title = "Chapter #{number}: #{chapter_title}"
  @chapter_text = chapter_contents(number)

  erb :chapter
end

get "/search" do
  @results = chapter_results(params[:query])

  erb :search
end
