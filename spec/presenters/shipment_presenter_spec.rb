require 'rails_helper'

describe ShipmentPresenter do
  it_behaves_like "a presenter with terms for a Citi resource"
  it_behaves_like "a presenter with related assets"
end