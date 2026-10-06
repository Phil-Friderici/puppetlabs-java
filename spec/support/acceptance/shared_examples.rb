# frozen_string_literal: true

# Shared examples for the Litmus acceptance tests of the java module.
#
# Including groups provide the inputs through `let` blocks, e.g.
#
#   it_behaves_like 'an idempotent manifest' do
#     let(:manifest) { "class { 'java': }" }
#   end

# Requires: `manifest`
RSpec.shared_examples 'an idempotent manifest' do
  it 'applies without errors and is idempotent' do
    expect { idempotent_apply(manifest) }.not_to raise_error
  end
end

# Requires: `java_bin` (path or command name), `expected_java_version` (Regexp)
RSpec.shared_examples 'a working java binary' do
  it 'runs and reports the expected version' do
    expect(java_binary_version(java_bin)).to match(expected_java_version)
  end
end

# Requires: `javac_bin` (path or command name), `expected_java_version` (Regexp)
RSpec.shared_examples 'a java development kit' do
  it 'provides a javac compiler reporting the expected version' do
    expect(javac_binary_version(javac_bin)).to match(expected_java_version)
  end
end

# Requires: `package_name`
RSpec.shared_examples 'an installed java package' do
  it 'installs the package' do
    expect(package(package_name)).to be_installed
  end
end

# Requires: `expected_java_home`
RSpec.shared_examples 'a configured JAVA_HOME' do
  it 'sets JAVA_HOME in /etc/environment' do
    expect(file('/etc/environment').content).to match(%r{^JAVA_HOME=#{Regexp.escape(expected_java_home)}$})
  end

  it 'points JAVA_HOME to an existing directory' do
    expect(file(expected_java_home)).to be_directory
  end
end
