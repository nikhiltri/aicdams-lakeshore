# frozen_string_literal: true
require 'rails_helper'

describe GenericWork do
  let(:user)         { create(:user1) }
  let(:example_file) { create(:asset) }

  subject { described_class.new }

  describe "::human_readable_type" do
    subject { described_class.human_readable_type }
    it { is_expected.to eq("Asset") }
  end

  context "without setting a type" do
    subject { build(:asset_without_type) }
    it "raises and error" do
      expect(-> { subject.save }).to raise_error(ArgumentError, "Can't assign a prefix without a type")
    end
  end

  describe "intial RDF types" do
    subject { described_class.new.type }
    it { is_expected.to include(AICType.Asset, AICType.Resource) }
  end

  describe "asserting StillImage" do
    subject { build(:asset) }
    specify { expect(subject.type).to include(AICType.Asset, AICType.StillImage) }
    context "and re-asserting StillImage" do
      before  { subject.assert_still_image }
      specify { expect(subject).not_to receive(:set_value) }
    end
    context "and asserting Text" do
      specify { expect(subject.assert_text).to be false }
    end
    describe "#to_solr" do
      let(:keyword) { create(:list_item) }

      before { subject.keyword = [keyword] }

      it "contains our custom solr fields" do
        expect(subject.to_solr[Solrizer.solr_name("aic_type", :facetable)]).to include("Asset", "Still Image")
        expect(subject.to_solr[Solrizer.solr_name("keyword", :facetable)]).to contain_exactly(keyword.pref_label)
        expect(subject.to_solr[Solrizer.solr_name("keyword", :stored_searchable)]).to contain_exactly(keyword.pref_label)
      end
    end
    describe "minting uids" do
      before { subject.save }
      it "uses a UID for still images" do
        expect(subject.id).to start_with("SI")
        expect(subject.uri).not_to match(/\/-/)
        expect(subject.uid).to eql(subject.id)
      end
    end
  end

  describe "setting type to Text" do
    subject { build(:text_asset) }
    specify { expect(subject.type).to include(AICType.Asset, AICType.Text) }
    context "and re-asserting Text" do
      before  { subject.assert_text }
      specify { expect(subject).not_to receive(:set_value) }
    end
    context "and asserting StillImage" do
      specify { expect(subject.assert_still_image).to be false }
    end
    describe "#to_solr" do
      specify { expect(subject.to_solr[Solrizer.solr_name("aic_type", :facetable)]).to include("Asset", "Text") }
    end
    describe "minting uids" do
      before { subject.save }
      it "uses a UID for still images" do
        expect(subject.id).to start_with("TX")
        expect(subject.uri).not_to match(/\/-/)
      end
    end
  end

  describe "metadata" do
    context "defined in the presenter" do
      AssetPresenter.terms.each do |term|
        it { is_expected.to respond_to(term) }
      end
    end
  end

  describe "cardinality" do
    [:capture_device, :dept_created, :digitization_source, :compositing, :light_type, :transcript].each do |term|
      it "limits #{term} to a single value" do
        expect(described_class.properties[term.to_s].multiple?).to be false
      end
    end
  end

  describe "loading from solr" do
    subject { ActiveFedora::Base.load_instance_from_solr(example_file.id) }
    it { is_expected.to be_kind_of described_class }
  end

  describe "#destroy" do
    it "deletes the resource" do
      expect(example_file.destroy).to be_kind_of(described_class)
    end
  end

  describe "#uid" do
    context "when changed" do
      subject do
        example_file.uid = "1234"
        example_file.save
        example_file.errors
      end
      its(:full_messages) { is_expected.to include("Uid must match id") }
    end
  end

  describe "#title" do
    let(:work) { described_class.new }
    subject { work.title.first }
    context "without a pref_label" do
      it { is_expected.to be_nil }
    end
    context "without a pref_label" do
      let(:work) { described_class.create(pref_label: "A Label") }
      it { is_expected.to eq("A Label") }
    end
  end

  describe "::accepts_uris_for" do
    let(:work) { build(:asset) }
    let(:item) { create(:list_item) }
    context "using a multi-valued term" do
      subject { work.keyword }
      context "with a string" do
        before { work.keyword_uris = [item.uri.to_s] }
        it { is_expected.to contain_exactly(item) }
      end
      context "with a RDF::URI" do
        before { work.keyword_uris = [item.uri] }
        it { is_expected.to contain_exactly(item) }
      end
      context "with a singular value" do
        it "raises an ArgumentError" do
          expect { work.keyword_uris = item.uri }.to raise_error(ArgumentError)
        end
      end
      context "with empty strings" do
        before { work.keyword_uris = [""] }
        it { is_expected.to be_empty }
      end
      context "with empty arrays" do
        before { work.keyword_uris = [] }
        it { is_expected.to be_empty }
      end
    end
    context "using a single-valued term" do
      subject { work.digitization_source }
      context "with a string" do
        before { work.digitization_source_uri = item.uri.to_s }
        it { is_expected.to eq(item) }
      end
      context "with a RDF::URI" do
        before { work.digitization_source_uri = item.uri }
        it { is_expected.to eq(item) }
      end
      context "with an empty string" do
        before { work.digitization_source_uri = "" }
        it { is_expected.to be_nil }
      end
    end
    context "with remaining terms" do
      it { is_expected.to respond_to(:document_type_uris=) }
      it { is_expected.to respond_to(:compositing_uri=) }
      it { is_expected.to respond_to(:light_type_uri=) }
      it { is_expected.to respond_to(:view_uris=) }
    end
  end
end