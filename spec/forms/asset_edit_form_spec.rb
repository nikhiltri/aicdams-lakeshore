require 'rails_helper'

describe AssetEditForm do

  describe "::permitted_annotation_params" do
    subject { AssetEditForm.permitted_annotation_params }
    it { is_expected.to include(:id, :_destroy, :content, { category: [] } ) }
  end

  describe "::build_permitted_params" do
    subject { AssetEditForm.build_permitted_params.map {|c| c.keys if c.is_a? Hash }.flatten }
    it { is_expected.to include(:comments_attributes, :aictag_ids, :tagcat_ids) }
  end

  describe "#initialize_field" do

    context "with comments" do
      let(:c1) { Comment.create(content: "first comment") }
      let(:c2) { Comment.create(content: "second comment") }
      let(:generic_file) do
        GenericFile.create.tap do |file|
          file.comments = [c1, c2]
          file.title = ["Commented resource"]
          file.apply_depositor_metadata "user"
          file.save!
        end
      end
      let(:form) { AssetEditForm.new(generic_file) }
      subject { form[:comments] }
      it { is_expected.to include(c1, c2) }
    end

    context "without comments" do
      let(:generic_file) do
        GenericFile.create.tap do |file|
          file.title = ["Un-Commented resource"]
          file.apply_depositor_metadata "user"
          file.save!
        end
      end
      let(:form) { AssetEditForm.new(generic_file) }
      subject { form[:comments] }
      it { is_expected.to include(Comment) }
    end

  end

  describe ".model_attributes" do
    let(:params) do 
      ActionController::Parameters.new( aictag_ids: [""] )
    end
    subject { described_class.model_attributes(params) }

    it "removes empty strings" do
      pending "this needs to apply to documents, representations and preferred representations"
      expect(subject["aictag_ids"]).to be_empty
    end
  end

end
