#module Jekyll
#  class BalanceChangeBlock < Jekyll::Hooks
#  end
#end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|

  doc.output.gsub!(
    ([^<\s]+)\s*--&gt;\s*([^<\s]+),
    '<span class="old">\1</span> → <span class="new">\3</span>'
  )

end