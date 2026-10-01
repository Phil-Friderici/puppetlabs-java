# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'java class with default parameters' do
  let(:expected_java_version) { java_version_pattern(default_java_major_version) }

  it_behaves_like 'an idempotent manifest' do
    let(:manifest) { java_class_manifest }
  end

  it_behaves_like 'an installed java package' do
    let(:package_name) { java_package_name('jdk') }
  end

  it_behaves_like 'a working java binary' do
    let(:java_bin) { 'java' }
  end

  it_behaves_like 'a java development kit' do
    let(:javac_bin) { 'javac' }
  end

  it_behaves_like 'a configured JAVA_HOME' do
    let(:expected_java_home) { java_home }
  end
end
