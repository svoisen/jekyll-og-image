# frozen_string_literal: true

class JekyllOgImage::Generator < Jekyll::Generator
  safe true

  def generate(site)
    base_path = File.join(
      JekyllOgImage.config.output_dir,
      "posts"
    )

    FileUtils.mkdir_p File.join(site.config["source"], base_path)

    site.posts.docs.each do |post|
      path = File.join(site.config["source"], base_path, "#{post.data['slug']}.png")

      if !File.exist?(path) || JekyllOgImage.config.force?
        Jekyll.logger.info "Jekyll Og Image:", "Generating image #{path}" if JekyllOgImage.config.verbose?
        generate_image_for_post(site, post, path)
      else
        Jekyll.logger.info "Jekyll Og Image:", "Skipping image generation #{path} as it already exists." if JekyllOgImage.config.verbose?
      end

      post.data["image"] ||= {
        "path" => File.join(base_path, "#{post.data['slug']}.png"),
        "width" => 1200,
        "height" => 600,
        "alt" => post.data["title"]
      }
    end
  end

  private

  def generate_image_for_post(site, post, path)
    date = post.date.strftime("%B %d, %Y")

    background_image = if JekyllOgImage.config.canvas["background_image"]
      File.read(File.join(site.config["source"], JekyllOgImage.config.canvas["background_image"]))
    end

    canvas = JekyllOgImage::Element::Canvas.new(1200, 600,
      background_color: JekyllOgImage.config.canvas["background_color"],
      background_image: background_image
    )

    if JekyllOgImage.config.border_bottom
      canvas = canvas.border(JekyllOgImage.config.border_bottom["width"],
        position: :bottom,
        fill: JekyllOgImage.config.border_bottom["fill"]
      )
    end

    if JekyllOgImage.config.image
      canvas = canvas.image(
        File.read(File.join(site.config["source"], JekyllOgImage.config.image)),
        gravity: :ne,
        width: 150,
        height: 150,
        radius: 50
      ) { |_canvas, _text| { x: 80, y: 100 } }
    end

    canvas = canvas.text(post.data["title"],
      width: JekyllOgImage.config.image ? 870 : 1040,
      color: JekyllOgImage.config.header["color"],
      dpi: 400,
      font: JekyllOgImage.config.header["font_family"]
    ) { |_canvas, _text| { x: 80, y: 100 } }

    canvas = canvas.text(date,
      gravity: :sw,
      color: JekyllOgImage.config.content["color"],
      dpi: 150,
      font: JekyllOgImage.config.content["font_family"]
    ) { |_canvas, _text| { x: 80, y: post.data["tags"].any? ? JekyllOgImage.config.margin_bottom + 50 : JekyllOgImage.config.margin_bottom } }

    if post.data["tags"].any?
      tags = post.data["tags"].map { |tag| "##{tag}" }.join(" ")

      canvas = canvas.text(tags,
        gravity: :sw,
        color: JekyllOgImage.config.content["color"],
        dpi: 150,
        font: JekyllOgImage.config.content["font_family"]
      ) { |_canvas, _text| { x: 80, y: JekyllOgImage.config.margin_bottom } }
    end

    if JekyllOgImage.config.domain
      canvas = canvas.text(JekyllOgImage.config.domain,
        gravity: :se,
        color: JekyllOgImage.config.content["color"],
        dpi: 150,
        font: JekyllOgImage.config.content["font_family"]
      ) do |_canvas, _text|
        {
          x: 80,
          y: post.data["tags"].any? ? JekyllOgImage.config.margin_bottom + 50 : JekyllOgImage.config.margin_bottom
        }
      end
    end

    canvas.save(path)
  end
end
