# frozen_string_literal: true

xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title "Conda recent packages"
    xml.description "Recent Conda packages"
    xml.link "https://conda.libraries.io"

    @entries.each do |entry|
      xml.item do
        xml.title entry[:name]
        xml.link "https://conda.libraries.io/package?name=#{entry[:name]}"
        xml.description "#{entry[:name]} updated on #{entry[:timestamp]}"
        xml.channel entry[:channel]
        xml.pubDate entry[:timestamp]
      end
    end
  end
end
