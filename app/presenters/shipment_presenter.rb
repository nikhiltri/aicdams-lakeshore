# frozen_string_literal: true
class ShipmentPresenter < Sufia::WorkShowPresenter
  def self.terms
    CitiResourceTerms.all
  end

  include CitiPresenterBehaviors

  def deleteable?
    current_ability.can?(:delete, Shipment)
  end
end
