require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ProjectList do
  describe "creation" do
    it "should set defaults" do
      p = Project.make!
      pl = p.project_list
      pl.should be_valid
      pl.title.should_not be_blank
      pl.description.should_not be_blank
    end
  end
end

describe ProjectList, "refresh_with_observation" do
  it "should remove taxa with no more confirming observations" do
    p = Project.make!
    pl = p.project_list
    t1 = Taxon.make!
    t2 = Taxon.make!
    o = make_research_grade_observation(:taxon => t1)
    
    pu = ProjectUser.make!(:user => o.user, :project => p)
    po = ProjectObservation.make!(:project => p, :observation => o)
    ProjectList.refresh_with_observation(o)
    pl.reload
    pl.taxon_ids.should include(o.taxon_id) #
    
    o.update_attributes(:taxon => t2)
    i = Identification.make!(:observation => o, :taxon => t2)
    Observation.set_quality_grade(o.id)
    o.reload
    
    ProjectList.refresh_with_observation(o, :taxon_id => o.taxon_id, 
      :taxon_id_was => t1.id, :user_id => o.user_id, :created_at => o.created_at)
    pl.reload
    pl.taxon_ids.should_not include(t1.id)
    pl.taxon_ids.should include(t2.id)
  end
  
  it "should give curator_identification precedence" do
    p = Project.make!
    pl = p.project_list
    t1 = Taxon.make!
    puts "t1: #{t1}"
    t2 = Taxon.make!
    puts "t2: #{t2}"
    o = make_research_grade_observation(:taxon => t1)
    
    pu = ProjectUser.make!(:user => o.user, :project => p)
    po = ProjectObservation.make!(:project => p, :observation => o)
    ProjectList.refresh_with_observation(o)
    pl.reload
    pl.taxon_ids.should include(o.taxon_id) #
    
    pu2 = ProjectUser.make!(:project => p, :role => ProjectUser::CURATOR) 
    i = without_delay { Identification.make!(:observation => o, :taxon => t2, :user => pu2.user) }
    po.reload
    ProjectList.refresh_with_project_observation(po, :observation_id => o.id, :taxon_id => t2.id, 
      :taxon_id_was => t1.id, :created_at => o.created_at)
    pl.reload
    pl.taxon_ids.should_not include(t1.id)
    pl.taxon_ids.should include(t2.id)
  end
  
  it "should confirm a species when a subspecies was observed" do
    species = Taxon.make!(:rank => "species")
    subspecies = Taxon.make!(:rank => "subspecies", :parent => species)
    p = Project.make!
    pl = p.project_list
    lt = pl.add_taxon(species, :user => p.user, :manually_added => true)
    po = make_project_observation_from_research_quality_observation(:project => p, :taxon => subspecies)
    Delayed::Worker.new(:quiet => true).work_off
    lt.reload
    lt.last_observation.should eq(po.observation)
  end
end

describe ProjectList, "reload_from_observations" do
  it "should not delete manually added taxa when descendant taxa have been observed" do
    p = Project.make!
    pl = p.project_list
    species = Taxon.make!(:rank => "species")
    subspecies = Taxon.make!(:rank => "subspecies", :parent => species)
    lt = pl.add_taxon(species, :manually_added => true, :user => p.user)
    po = make_project_observation(:project => p, :taxon => subspecies)
    Delayed::Worker.new(:quiet => true).work_off
    ProjectList.reload_from_observations(pl)
    ListedTaxon.find_by_id(lt.id).should_not be_blank
  end
end
