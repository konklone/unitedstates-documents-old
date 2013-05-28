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

          # for some nodes, we'll preserve some attributes
          # turn into a div or span with a class of its old name
          node = xml_to_html(node)
        end

        body.to_html
      end

      # Static: Preserve citation for usc legal docs
      #
      # node      - the Nokogiri::XML node
      # preserved - the Hash of preserved values
      #
      # Examples:
      #   node: <external-xref legal-doc="usc" parsable-cite="usc/12/5301" ... />
      #   cite_check(node)
      #   # => {
      #   #  "data-citation-type" => "usc",
      #   #  "data-citation-id"   => "usc/12/5301"
      #   # }
      #
      # Returns a new hash with data-citation-type
      #   and data-citation-id set to the given values in the external-xref
      #   if it is a USC legal doc and this node is an external-xref one
      def self.citations(node)
        preserved = {}
        if external_xref?(node) and usc_legal_doc?(node)
          preserved["data-citation-type"] = "usc"
          preserved["data-citation-id"]   = node.attributes["parsable-cite"].value
        end
        preserved
      end

      # Static: Determined if a node is an external-xref node
      #
      # node - the Nokogiri::XML node
      #
      # Returns true if the node is an external-xref node, false otherwise
      def self.external_xref?(node)
        node.name == "external-xref"
      end

      # Static: Determined if a node is a node representing the ref to a USC legal doc
      #
      # node - the Nokogiri::XML node
      #
      # Returns true if the node is a node representing a USC legal doc, false otherwise
      def self.usc_legal_doc?(node)
        node.attributes["legal-doc"] &&
          node.attributes["legal-doc"].value == "usc"
      end

      # Static: Transform the XML node to an HTML one
      #
      # node - the Nokogiri::XML node from the XML doc
      #
      # Returns the HTML node with the proper attributes
      def self.xml_to_html(node)
        preserved = Hash.new
          .merge(citations(node))
          .merge({"class" => node.name})
        node.name = html_node_name(node)
        replace_attributes(node, preserved)
      end

      # Static: Fetch the corresponding HTML tag name for the given node
      #
      # node - the Nokogiri::XML node
      #
      # Returns the proper HTML name for the given node 
      def self.html_node_name(node)
        BLOCKS.include?(node.name) ? "div" : "span"
      end

      # Static: Strip out all the node's attributes and set those which were preserved
      #
      # node      - the Nokogiri::XML node
      # preserved - the hash of preserved node attributes
      # 
      # Returns the node with just the attributes which were in the preserved Hash
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
