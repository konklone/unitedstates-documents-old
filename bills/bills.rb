require 'nokogiri'

module UnitedStates
  module Documents
    class Bills

      # elements to be turned into divs (must be listed explicitly).
      BLOCKS = %w{
        bill form amendment-form engrossed-amendment-form resolution-form
        legis-body resolution-body engrossed-amendment-body amendment-body
        title
        amendment amendment-block amendment-instruction
        section subsection paragraph subparagraph subchapter clause
        quoted-block
        toc toc-entry
        p
      }

      # to always be surrounded with a p tag when blocks mode is on
      DISPLAY_BLOCKS = %w{ continuation-text official-title }

      # Given a path to an XML file published by the House or Senate,
      # produce an HTML version of the document at the given output.
      def self.process(text, options = {})

        doc = Nokogiri::XML text


        # first (optional) pass: structural alteration
        if options[:blocks]
          add_blocks doc
        end


        # main pass: process all nodes

        # document counter - number any existing block units from previous pass
        counter = 0

        doc.search("*").each do |node|

          if node.name == "metadata"
            node.remove
            next
          end

          # preserve the node's old name as its class
          preserved = {"class" => node.name}

          # break out any detected cites
          preserved.merge! citations(node)


          if node.name == "p"
            counter += 1

            if options[:block_id].is_a?(Proc)
              id = options[:block_id].call counter
            else
              id = counter
            end

            preserved.merge! "data-block-id" => id
          end


          # switch the name to a div or span
          node.name = html_node_name node

          # strip out all attributes
          node.attributes.each do |key, value|
            node.attributes[key].remove
          end

          # allow client to transform per-node -
          # they get the stripped node, and the attributes hash we're about to commit.
          # they can be modified in place before committed to the document.
          yield node, preserved if block_given?

          # restore just the ones we were going to preserve
          preserved.each do |key, value|
            node.set_attribute key, value.to_s
          end
        end

        doc.root.to_html
      end


      # Break out and preserve detected citation details
      # e.g. a parsable-cite of usc/12/5301 yields:
      #   {
      #    "data-citation-type" => "usc",
      #    "data-citation-id"   => "usc/12/5301"
      #   }
      def self.citations(node)
        citations = {}
        if (node.name == "external-xref") and
          (node.attributes["legal-doc"] && node.attributes["legal-doc"].value == "usc")
          citations["data-citation-type"] = "usc"
          citations["data-citation-id"]   = node.attributes["parsable-cite"].value
        end
        citations
      end

      # Fetch the corresponding HTML tag name for the given node
      def self.html_node_name(node)
        BLOCKS.include?(node.name) ? "div" : "span"
      end

      def self.containerify(doc, nodes)
        nodes = [nodes] unless nodes.is_a?(Array)
        p = Nokogiri::XML::Node.new "p", doc
        nodes.first.add_previous_sibling p

        nodes.each {|node| node.parent = p}
      end

      def self.add_blocks(doc)
        # put some things in containers that need to be for meaningful display.
        doc.search("*").each do |node|
          # if the node's an <enum>, and it's not in a title or section -
          # scoop up it and any immediate sibling <header> and <text> elements,
          # and put them inside a container of <div class="p">.
          if node.name == "enum"
            unless ["section", "title"].include?(node.parent.name)
              brother_header, brother_text = [nil, nil]

              if node.next_sibling.name == "header"
                brother_header = node.next_sibling
              end

              if brother_header and brother_header.next_sibling.name == "text"
                brother_text = brother_header.next_sibling
              end

              containerify doc, [node, brother_header, brother_text].compact
            end
          end

          # do it if the node's a <text>, and its immediate parent is a <section>
          if (node.name == "text") and (node.parent.name == "section")
            containerify doc, node
          end

          # do the same for some other nodes
          if DISPLAY_BLOCKS.include?(node.name)
            containerify doc, node
          end
        end
      end

    end
  end
end
