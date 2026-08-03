Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|

  apply =
    # Everything in _posts
    (doc.respond_to?(:collection) && doc.collection.label == "posts") ||
    # Generated changelogs
    doc.respond_to?(:path) && File.basename(doc.path) == "fafbeta.md" ||
    doc.respond_to?(:path) && File.basename(doc.path) == "fafdevelop.md"

  next unless apply

  # Use https://regex101.com/ to debug regex.
  doc.output.gsub!(
    /<li>([^<]+?)<ul>\s*<li>([^<]+?:\s)([^<]+)\s-&gt;\s([^<]+)<\/li>/,
    '<li><span class="change-category">\1</span><ul> <li><span class="change">\2</span><span class="old">\3</span> → <span class="new">\4</span></li>'
  )

  # Needed if there is more than one change per category
  doc.output.gsub!(
    /<li>([^<]+?:\s)([^<]+)\s-&gt;\s([^<]+)<\/li>/,
    '<li><span class="change">\1</span><span class="old">\2</span> → <span class="new">\3</span></li>'
  )

end