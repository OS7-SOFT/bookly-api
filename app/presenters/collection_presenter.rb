class CollectionPresenter
  def initialize(collection, presenter_class)
    @collection = collection
    @presenter_class = presenter_class
  end

  def as_json(*)
    @collection.map do |record|
      @presenter_class.new(record).as_json
    end
  end
end
