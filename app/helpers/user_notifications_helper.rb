# frozen_string_literal: true

module UserNotificationsHelper
  include GlobalPath  # Include helper methods from GlobalPath module

  # Indents a string by the specified amount (default 2 spaces)
  # Useful for formatting text within emails
  def indent(text, by = 2)
    spacer = " " * by  # Create a spacer string with the desired indentation
    result = +""        # Initialize an empty string
    text.each_line { |line| result << spacer << line }  # Iterate over each line, prepend spacer and append to result
    result
  end

  # Corrects the top margin of an HTML fragment to a desired value
  # Takes the HTML string and the desired margin as arguments
  def correct_top_margin(html, desired)
    fragment = Nokogiri::HTML5.fragment(html)  # Parse the HTML string into a fragment
    if para = fragment.css("p:first").first  # Find the first paragraph element
      para["style"] = "margin-top: #{desired};"  # Set the style attribute for margin-top
    end
    fragment.to_html.html_safe                  # Convert the fragment back to HTML and mark it safe
  end

  # Retrieves the URL for the site logo
  # Attempts to use the site digest logo URL first, falling back to the normal site logo URL
  # Returns nil if neither logo URL is available or ends in .svg
  def logo_url
    logo_url = SiteSetting.site_digest_logo_url  # Check for digest logo URL
    logo_url = SiteSetting.site_logo_url if logo_url.blank? || logo_url =~ /\.svg\z/i  # Fallback to normal logo if digest logo is blank or ends in .svg
    return nil if logo_url.blank? || logo_url =~ /\.svg\z/i  # Don't use URLs ending in .svg
    logo_url
  end

  # Generates an HTML link for the site name with the base URL
  def html_site_link
    "<a href='#{Discourse.base_url}'>#{@site_name}</a>"  # Create an anchor tag with base URL and site name
  end

  # Extracts the first paragraphs with text from an HTML string
  # Returns the HTML content of the first paragraphs up to a certain length
  # If no paragraphs with text are found, it searches for other elements like images or oneboxes
  def first_paragraphs_from(html)
    doc = Nokogiri::HTML5(html)  # Parse the HTML string into a document

    result = +""                # Initialize an empty string
    length = 0                   # Track the total length of extracted text

    doc.css("body > p, aside.onebox, body > ul, body > blockquote").each do |node|
      if node.text.present?    # Check if the node has text content
        result << node.to_s      # Append the node's HTML to the result
        length += node.inner_text.length  # Add the length of the node's text to the total
        return result if length >= SiteSetting.digest_min_excerpt_length  # Return if length exceeds minimum excerpt length
      end
    end

    return result if result.present?  # Return the result if any paragraphs were found

    # If no text paragraphs found, return the first non-empty element (paragraph, image, onebox)
    doc.css("body > p:not(:empty), body > div:not(:empty), body > p > div.lightbox-wrapper img").first
  end

  # Generates an email excerpt from HTML content
  # Takes the HTML string and optionally a post object as arguments
  # Uses PrettyText to format the HTML for email and marks it safe
  def email_excerpt(html_arg, post = nil)
    html = (first_paragraphs_from(html_arg) || html_arg).to_s  # Get the first paragraphs or the original HTML
    PrettyText.format_for_email(html, post).html_safe
  end

  # Normalizes a name by converting it to lowercase and removing spaces, underscores, and hyphens
  def normalize_name(name)
    name.downcase.gsub(/[\s_-]/, "")
  end

  # Determines whether to show the username on a post
  # Considers SiteSetting options for enabling names and displaying names on posts
  # Also checks
