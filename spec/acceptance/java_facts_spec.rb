# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'java custom facts' do
  before(:all) do
    apply_manifest(java_class_manifest, catch_failures: true)
    @java_facts = java_facts
  end

  let(:facts) { @java_facts } # rubocop:disable RSpec/InstanceVariable

  it 'resolves java_version to the installed version' do
    expect(facts['java_version']).to match(java_version_pattern(default_java_major_version))
  end

  it 'resolves java_version to the version reported by the java binary' do
    expect(facts['java_version']).to eq(java_binary_version('java'))
  end

  it 'resolves java_major_version' do
    expect(facts['java_major_version']).to eq(default_java_major_version)
  end

  it 'resolves java_patch_level' do
    expect(facts['java_patch_level']).to match(%r{\A\d+\z})
  end

  it 'resolves java_default_home to the home of the default java binary' do
    expect(file("#{facts['java_default_home']}/bin/java")).to be_executable
  end

  it 'resolves java_libjvm_path to the directory containing libjvm.so' do
    expect(file("#{facts['java_libjvm_path']}/libjvm.so")).to be_file
  end
end
