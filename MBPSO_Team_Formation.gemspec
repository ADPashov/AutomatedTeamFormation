require_relative 'lib/MBPSO_Team_Formation/version'

Gem::Specification.new do |spec|
  spec.name          = 'MBPSO_Team_Formation'
  spec.version       = MBPSOTeamFormation::VERSION
  spec.authors       = ['Anton Pashov ']
  spec.email         = ['anton.pashov@kcl.ac.uk']

  spec.summary       = %q(Automated team formation using modified binary particle swarm optimisation.)
  spec.homepage      = 'https://github.kcl.ac.uk/k1631446/MBPSO_Team_Formation'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
  
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.kcl.ac.uk/k1631446/MBPSO_Team_Formation'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = %w[lib/MBPSO_Team_Formation.rb lib/MBPSO_Team_Formation/version.rb lib/MBPSO_Team_Formation/mbpso.rb lib/MBPSO_Team_Formation/validation.rb lib/MBPSO_Team_Formation/mvh.rb lib/MBPSO_Team_Formation/neighbourhood.rb lib/MBPSO_Team_Formation/particle.rb]
  #     Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
