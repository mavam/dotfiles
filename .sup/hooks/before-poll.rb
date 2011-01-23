require "#{ENV['HOME']}/.sup/hooks/common.rb"

@slice_manager ||= SliceManager.new
@slice_manager.check_current_slice
