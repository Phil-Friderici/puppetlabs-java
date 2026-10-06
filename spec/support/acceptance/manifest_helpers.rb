# frozen_string_literal: true

module JavaAcceptanceHelpers::ManifestHelpers
  def java_class_manifest(params = {})
    return "class { 'java': }" if params.empty?

    width = params.keys.map { |key| key.to_s.length }.max
    lines = params.map { |key, value| "  #{key.to_s.ljust(width)} => '#{value}'," }
    "class { 'java':\n#{lines.join("\n")}\n}"
  end
end
