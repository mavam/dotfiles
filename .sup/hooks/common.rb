# Monkey-patch the source manager to enable forced updates of sources.yaml
# after aging a slice.
class Redwood::SourceManager
  def save_sources!(fn=Redwood::SOURCE_FN)
    @sources_dirty = true
    save_sources(fn)
  end
end

# Manages an email archive that is split into slices, each of which represent a
# horizontal partition of the entire archive.
class SliceManager
  attr_reader :base

  def initialize(base=nil)
    @base = base || "#{ENV['HOME']}/.mail"
  end

  # Crawl through the entire mail collection except for the current slice and
  # add all old sources as unusual. This should be done at startup.
  def check_old_slices
    debug("checking old slices")
    Dir.glob("#{@base}/20??/[0-9][0-9]/*").each do |dir| 
      next if dir =~ /^#{current_slice}/
      add_source(dir, poll=false, archive=true) { |uri| create_labels(uri) }
    end
  end

  # Ensure that all maildir directories in the current slice are registered
  # sources and that the sent source of the current slice is used.
  def check_current_slice
    debug("checking current slice")
    Dir.glob("#{current_slice}/*").each do |dir| 
      add_source(dir, poll=true, archive=(dir[/\w+$/] != "inbox")) do |uri|
        create_labels(uri)
      end
    end

    sent_dir = "#{current_slice}/sent"
    sent_uri = "maildir:#{sent_dir}"
    if File.exists?(sent_dir)
      src = Redwood::SourceManager.source_for(sent_uri) 
      unless src and src.uri == Redwood::SentManager.source_uri
        debug("using existing sent source #{src.uri}")
        Redwood::SentManager.source = src
      end
    else
      Redwood::Logger.force_message("creating new sent source #{sent_uri}")
      add_source(sent_dir, poll=true, archive=true) { |uri| [:sent] }
    end

    aging_needed = Redwood::SourceManager.usual_sources.any? do |src| 
      # Only consider sources in the mail base (e.g., not sup://drafts).
      src.uri.include?(@base) && ! src.uri.include?(current_slice) 
    end
    age(previous_slice) if aging_needed
  end

  # Get the path of the current slice.
  def current_slice
    "#{@base}/#{Date.today.strftime("%Y/%m")}"
  end

  private

  # Get the path of the previous slice.
  def previous_slice
    today = Date.today
    last = "#{@base}/"
    if today.month == 1 
      last << "#{today.year - 1}/12"
    else
      last << "#{today.year}/%02d" % (today.month - 1)
    end

    last
  end

  # Create labels for a given source URI.
  def create_labels(uri)
    dir = uri.split('/').last
    dir == "inbox" ? [] : dir.split('.').map! { |l| l.to_sym }
  end

  # Register a Maildir source.
  # @param [String] The path on disk pointing to the Maildir source.
  # @param [Boolean] Whether the source should be polled, i.e., is a usual source.
  # @param [Boolean] Whether the source should be archived.
  # @param [Proc] The block that returns an array of labels for a given source URI.
  def add_source(path, poll=true, archive=false, &block)
    uri = "maildir:#{path}"
    return if Redwood::SourceManager.source_for(uri)

    unless File.exists?(path)
      ["cur", "tmp", "new"].each do |dir| 
        FileUtils.mkpath("#{path}/#{dir}", :mode => 0700)
      end
    end

    labels = yield(uri) || []
    Redwood::Logger.force_message("adding source #{uri} [#{labels * ", "}]")
    src = Redwood::Maildir.new(uri, poll, archive, nil, labels)
    Redwood::SourceManager.add_source(src)
    Redwood::PollManager.poll_from(src) 
    Redwood::SourceManager.save_sources
  end

  # Render all sources of a slice unusual, i.e., avoid polling.
  # @param [String] The path to the slice.
  def age(slice)
    debug("aging slice #{slice}")
    Dir.glob("#{slice}/*").each do |dir| 
      uri = "maildir:#{dir}"
      src = Redwood::SourceManager.source_for(uri) 
      if src.usual?
        Redwood::Logger.force_message("aging source #{uri}")
        src.usual = false
      end
    end

    Redwood::SourceManager.save_sources!
  end
end
