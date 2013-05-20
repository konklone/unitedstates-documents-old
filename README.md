## Documents

Tools, ideas, and maybe some light standards for working with US documents.

### At The Moment

There are lots of different legal documents, and lots of websites and applications that want to display or otherwise integrate them. There aren't many great reusable tools out there for working with them, in part because what standards exist tend to be optimized for precision, longevity, and authoring tools. It's very non-simple.

This repository is an attempt to capture efforts and experimentation to simplify this scene, and to link to other existing and useful efforts.

### Document Processor

This repository contains a `us-documents` gem that provides command line and Ruby-based document processors for two kinds of legal documents:

* XML for bills in Congress, as distributed by [GPO's FDSys](http://www.gpo.gov/fdsys/)
* HTML for Federal Register rules and notices, as distributed by [FederalRegister.gov](https://www.federalregister.gov)

Both processors turn the original documents into simple HTML fragments suitable for direct integration.

Install the gem with:

```bash
gem install us-documents
```

And process a bill or Federal Register document with:

```bash
us-documents bills /path/to/original/bill.xml

us-documents federal_register /path/to/original/rule.html
```

The resulting HTML will print to `STDOUT`. 

In Ruby, the processor takes in a string and outputs a string:

```ruby
require 'open-uri'
require 'us-documents'

bill_text = open("http://www.gpo.gov/fdsys/pkg/BILLS-113hr624rfs/xml/BILLS-113hr624rfs.xml").read
bill_html = UnitedStates::Documents::Bills.process bill_text

fr_text = open("https://www.federalregister.gov/articles/html/full_text/201/310/114.html").read
fr_html = UnitedStates::Documents::FederalRegister.process fr_text
```


#### Bills from Congress

Congress publishes XML for every bill in the House and Senate, and they (thankfully) share a common schema. They also provide a proper DTD, and XML stylesheets.

The `us-documents` bill processor does a few things to prepare HTML for integration:

* Turns each tag into a span or div, with a class from the original tag name.
* Drops most attributes - there are a lot of them, and it's not obvious what they all signify.
* Take Congress-detected citation links, parse out the pieces (e.g. title, section), and put them into data attributes. This allows downstream users to easily link citations to other sources.

This turns XML of the style ([source](http://www.gpo.gov/fdsys/pkg/BILLS-113hr624rfs/xml/BILLS-113hr624rfs.xml)):

```xml
<section id="HB0C08BA314F34BDFB081CA26A4A48B86" section-type="section-one">
  <enum>1.</enum>
  <header>Short title</header>
  <text display-inline="no-display-inline">
    This Act may be cited as the
    <quote>
      <short-title>
        Cyber Intelligence Sharing and Protection Act
      </short-title>
    </quote>.
  </text>
</section>
```

into this HTML:

```html
<div class="section">
  <span class="enum">1.</span>
  <span class="header">Short title</span>
  <span class="text">
    This Act may be cited as the 
    <span class="quote">
      <span class="short-title">
        Cyber Intelligence Sharing and Protection Act
      </span>
    </span>.
  </span>
</div> 
```

You can see an example of this HTML used in production on [Scout's page for H.R. 624](https://scout.sunlightfoundation.com/item/bill/hr624-113).

#### Federal Register rules and notices

[FederalRegister.gov](https://www.federalregister.gov) publishes well structured JSON metadata for every document on the site. They also break out standalone HTML fragments for the abstract and body of every document.

For example, this [rule about cotton](https://www.federalregister.gov/articles/2013/04/30/2013-10114/revision-of-regulations-defining-bona-fide-cotton-spot-markets) has [JSON metadata](https://www.federalregister.gov/api/v1/articles/2013-10114) that links to raw HTML links for both the [abstract](https://www.federalregister.gov/articles/html/abstract/201/310/114.html) and [body](https://www.federalregister.gov/articles/html/full_text/201/310/114.html). 

That HTML is already designed for direct integration, but there are changes we can make, to make integration easier:

* Remove `id`, `onclick`, and `target` attributes.
* Turn relative links into absolute links (to `https://www.federalregister.gov`).
* Take FR.gov-detected citation links, parse out the pieces (e.g. title, section), and put them into data attributes. This allows downstream users to easily link citations to other sources.
* Drops an empty tool tip container.

This turns HTML of the style ([source](https://www.federalregister.gov/articles/html/full_text/201/310/114.html)):

```html
<div class="body_column">
  <p id="p-8" data-page="25181">
    Pursuant to requirements set forth in the Regulatory Flexibility Act (RFA) (<a class="usc external" href="http://api.fdsys.gov/link?collection=uscode&amp;title=5&amp;year=mostrecent&amp;section=601&amp;type=usc&amp;link-type=html" target="_blank">5 U.S.C. 601</a>-612), AMS has considered the economic impact of this action on small entities and has determined that its implementation will not have a significant economic impact on a substantial number of small businesses.
  </p>
</div>
```

into this similar HTML:

```html
<div class="body_column">
  <p data-page="25181" data-id="p-8">
    Pursuant to requirements set forth in the Regulatory Flexibility Act (RFA) (<a class="usc external" href="http://api.fdsys.gov/link?collection=uscode&amp;title=5&amp;year=mostrecent&amp;section=601&amp;type=usc&amp;link-type=html" data-title="5" data-section="601">5 U.S.C. 601</a>-612), AMS has considered the economic impact of this action on small entities and has determined that its implementation will not have a significant economic impact on a substantial number of small businesses.
  </p>
</div>
```

You can see an example of this used in production on [Scout's page for document No. 2013-10114](https://scout.sunlightfoundation.com/item/regulation/2013-10114).