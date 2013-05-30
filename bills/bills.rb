require 'nokogiri'

module UnitedStates
  module Documents
    class Bills

      # elements to be turned into divs (must be listed explicitly)
      BLOCKS = %w{
        bill form amendment-form engrossed-amendment-form resolution-form
        legis-body resolution-body engrossed-amendment-body amendment-body
        title
        amendment amendment-block amendment-instruction
        section subsection paragraph subparagraph subchapter clause
        quoted-block
        toc toc-entry
      }

      # elements to be turned into spans (unlisted elements default to inline)
      INLINES = %w{
        after-quoted-block quote
        internal-xref external-xref
        text header enum
        short-title official-title
      }

      # Given a path to an XML file published by the House or Senate,
      # produce an HTML version of the document at the given output.
      def self.process(text, options = {})
        doc = Nokogiri::XML text

        body = doc.root
        body.traverse do |node|

          if node.name == "metadata"
            node.remove
            next
          end

          # preserve the node's old name as its class
          preserved = {"class" => node.name}

          # break out any detected cites
          preserved.merge! citations(node)

          # switch the name to a div or span
          node.name = html_node_name node

          # strip out extraneous attributes
          replace_attributes node, preserved
        end

        body.to_html
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

      # Strip out all the node's attributes and set those which were preserved
      def self.replace_attributes(node, preserved)
        # strip out all attributes
        node.attributes.each do |key, value|
          node.attributes[key].remove
        end

        # restore just the ones we were going to preserve
        preserved.each do |key, value|
          node.set_attribute key, value
        end

        node
      end

    end
  end
end
