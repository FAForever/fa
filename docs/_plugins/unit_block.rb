module Jekyll
  class UnitBlock < Liquid::Block

    def initialize(tag_name, markup, tokens)
      super
      @unit_id = markup.strip
    end

    def render(context)
      name = super.strip

      page = context.registers[:page]

      is_post = page["collection"] == "posts"
      is_fafbeta = File.basename(page["path"]) == "fafbeta.md"
      is_fafdevelop = File.basename(page["path"]) == "fafdevelop.md"

      apply = is_post || is_fafbeta || is_fafdevelop
      unless apply
        return "{% unit #{@unit_id} %}\n#{name}\n{% endunit %}"
      end

      icon_name =
        if @unit_id.start_with?("enhancements")
          "#{@unit_id}.png"
        else
          "#{@unit_id.upcase}_icon.png"
        end

      <<~HTML
      <div class="unit-header">
        <img class="unit-icon"
             src="/assets/icons/#{icon_name}">
        <span class="unit-name">#{name}</span>
      </div>
      HTML
    end
  end
end

Liquid::Template.register_tag('unit', Jekyll::UnitBlock)