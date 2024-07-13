---
layout: page
title: Patches
permalink: /patches
nav_order: 8
---

# All Game Patches

<ul style="columns: 2">
  {% for post in site.posts %}
    <li>
      <a class="preview-title" href="{{ post.url }}">{{ post.title }}</a>
      <span>{{ post.date | date: "%b %d %Y" }}</span>
    </li>
  {% endfor %}
</ul>
