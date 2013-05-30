require 'nokogiri'

module UnitedStates
  module Documents
    class Bills

      # elements to be turned into divs (must be listed explicitly).
      # these will also be used to advance a document counter that numbers
      # each block, to give identifiers per-displayable unit.
      BLOCKS = %w{
        bill form amendment-form engrossed-amendment-form resolution-form
        legis-body resolution-body engrossed-amendment-body amendment-body
        title
        amendment amendment-block amendment-instruction
        section subsection paragraph subparagraph subchapter clause
        quoted-block
        toc toc-entry
      }

      # Given a path to an XML file published by the House or Senate,
      # produce an HTML version of the document at the given output.
      def self.process(text, options = {})
        doc = Nokogiri::XML text

        # document counter - number units as the document proceeds
        counter = 0

        body = doc.root
        body.traverse do |node|

          if node.name == "metadata"
            node.remove
            next
          end

          # preserve the node's old name as its class
          preserved = {"class" => node.name}

          # detect this node's place in the hierarchy
          if block?(node)
            counter += 1
            data = {"data-block" => counter}

            if options[:hierarchy].is_a?(Proc)
              data["data-block"] = options[:hierarchy].call counter
            end

            preserved.merge! data
          end

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
        block?(node) ? "div" : "span"
      end

      def self.block?(node)
        BLOCKS.include? node.name
      end

      # Strip out all the node's attributes and set those which were preserved
      def self.replace_attributes(node, preserved)
        # strip out all attributes
        node.attributes.each do |key, value|
          node.attributes[key].remove
        end

        # restore just the ones we were going to preserve
        preserved.each do |key, value|
          node.set_attribute key, value.to_s
        end

        node
      end

    end
  end
end
