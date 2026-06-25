module ApplicationHelper
  FLASH_STYLES = {
    "notice"  => "bg-emerald-50 border-emerald-200 text-emerald-800",
    "success" => "bg-emerald-50 border-emerald-200 text-emerald-800",
    "alert"   => "bg-rose-50 border-rose-200 text-rose-800",
    "error"   => "bg-rose-50 border-rose-200 text-rose-800"
  }.freeze

  def flash_classes(type)
    FLASH_STYLES.fetch(type.to_s, "bg-sky-50 border-sky-200 text-sky-800")
  end

  # Renders an Active Storage image variant, or a coloured placeholder with a
  # location pin when no image is attached.
  def attachment_image(attachment, css: "", alt: "", variant: nil)
    if attachment.attached?
      source = variant ? attachment.variant(**variant) : attachment
      image_tag source, class: css, alt: alt, loading: "lazy"
    else
      placeholder_image(css)
    end
  end

  # Coloured circular avatar using the user's initials.
  def avatar_for(user, size: "w-10 h-10")
    initials = user.name.to_s.split.map(&:first).first(2).join.upcase
    content_tag :div,
                initials,
                class: "#{size} shrink-0 rounded-full bg-indigo-600 text-white flex items-center justify-center font-semibold"
  end

  private

  def placeholder_image(css)
    content_tag :div, class: "flex items-center justify-center bg-gradient-to-br from-indigo-100 to-sky-100 text-indigo-300 #{css}" do
      tag.svg(class: "w-1/4 h-1/4 min-w-8 min-h-8", fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor") do
        tag.path("stroke-linecap": "round", "stroke-linejoin": "round",
                 d: "M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z")
      end
    end
  end
end
