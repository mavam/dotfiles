require "#{ENV['HOME']}/.sup/hooks/common.rb"

@slice_manager ||= SliceManager.new
@slice_manager.check_old_slices
@slice_manager.check_current_slice

#Redwood::DRAFT_DIR = "#{@slice_manager.base}/drafts"
