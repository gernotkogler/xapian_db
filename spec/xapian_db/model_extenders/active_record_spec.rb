# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe XapianDb::ModelExtenders::ActiveRecord do

  let (:subject) { Object.extend XapianDb::ModelExtenders::ActiveRecord }

  describe ".inherited(klass)" do

    it "checks if a blueprint for the klass is specified" do
      XapianDb::DocumentBlueprint.should_receive(:configured?).with(ActiveRecordObject.name)
      subject.inherited(ActiveRecordObject)
    end

    it "calls blueprint._adapter.add_class_helper_methods_to(klass) if a blueprint for the class is configured" do
      XapianDb::DocumentBlueprint.setup(:ActiveRecordObject) do |blueprint|
        blueprint.attribute :array
      end
      XapianDb::DocumentBlueprint.blueprint_for(:ActiveRecordObject)._adapter.should_receive(:add_class_helper_methods_to).with(ActiveRecordObject)
      subject.inherited(ActiveRecordObject)
    end

  end

end