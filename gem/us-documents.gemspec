Gem::Specification.new do |s|
  s.name        = 'us-documents'
  s.version     = '0.1.1'
  
  s.summary     = "Process legal documents into integration-friendly HTML."
  s.description = "Process legal documents into integration-friendly HTML."

  s.authors     = ["Eric Mill"]
  s.email       = 'eric@sunlightfoundation.com'
  
  s.homepage    = 'https://github.com/unitedstates/documents'

  s.files       = [
                    "bin/us-documents",
                    "lib/bills.rb",
                    "lib/federal_register.rb",
                    "lib/us-documents.rb"
                  ]
  s.require_paths = ["lib"]
  s.bindir = 'bin'

  s.add_dependency "nokogiri"
end