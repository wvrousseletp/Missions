import sys
from pbxproj import XcodeProject

try:
    project_path = 'Missions.xcodeproj/project.pbxproj'
    project = XcodeProject.load(project_path)
    
    for file in project.get_files_by_name('ContentView.swift'):
        project.remove_file_by_id(file.get_id())
        
    groups = project.get_groups_by_name('Missions')
    if groups:
        missions_group = groups[0]
        project.add_folder('Missions/Models', parent=missions_group)
        project.add_folder('Missions/Views', parent=missions_group)
    else:
        print("Could not find Missions group")
        
    project.save()
    print("Successfully updated project")
except Exception as e:
    print(f"Error: {e}")
