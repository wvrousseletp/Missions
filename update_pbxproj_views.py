import sys
from pbxproj import XcodeProject

try:
    project_path = 'Missions.xcodeproj/project.pbxproj'
    project = XcodeProject.load(project_path)
    
    groups = project.get_groups_by_name('Views')
    if groups:
        views_group = groups[0]
        project.add_file('Missions/Views/AddSectorView.swift', parent=views_group, force=False)
        project.add_file('Missions/Views/SectorDetailView.swift', parent=views_group, force=False)
        project.add_file('Missions/Views/AddProjectView.swift', parent=views_group, force=False)
        project.add_file('Missions/Views/ProjectDetailView.swift', parent=views_group, force=False)
    else:
        print("Could not find Views group")
        
    project.save()
    print("Successfully updated project")
except Exception as e:
    print(f"Error: {e}")
