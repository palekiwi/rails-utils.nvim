local config = {
  spec_dir = "spec",
  command = { "docker", "exec", "spabreaks-test-1", "bin/rspec", "--format", "j" },
  colors = {
    test_success = "#6e9440",
    test_failure = "#cc6666",
  },
}

return config
