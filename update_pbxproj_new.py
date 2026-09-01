import sys
from pbxproj import XcodeProject

try:
    project_path = 'Missions.xcodeproj/project.pbxproj'
    project = XcodeProject.load(project_path)
    
    groups = project.get_groups_by_name('Views')
    if groups:
        views_group = groups[0]
        # We need to add the two new files to the Views group.
        # Note: add_file takes the file path and optionally the parent group.
        # Since the files are already in the correct folder, we just pass the path.
        project.add_file('Missions/Views/QuickCaptureView.swift', parent=views_group, force=False)
        project.add_file('Missions/Views/FocusModeView.swift', parent=views_group, force=False)
    else:
        print("Could not find Views group")
        
    project.save()
    print("Successfully updated project")
except Exception as e:
    print(f"Error: {e}")
