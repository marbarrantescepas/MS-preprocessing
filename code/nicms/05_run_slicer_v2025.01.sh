#======================================================================
#   OPEN FLAIR, T1w, BRAIN + LESION SEGMENTATION MASK USING SLICER
#======================================================================

#@author: julia r. jelgeruis, lonneke bos, mar barrantes cepas
#@email: m.barrantescepas@amsterdamumc.nl
#updated: 03 February 2025, in process
#to-do: simplify usage

#Description: this code is meant to open 3DSlicer and load the T2FLAIR and 
# overlaying lesion mask with optimal parameters for 
# manual correction of the lesion masks obtained in the previous step. 
# Input: 
# Output: 
# Run: Slicer --python-script run_slicer_v2025.01.sh [SUBJ_ID] &

# Requirements:
# 1. Please install FSL and Slicer, if they are not already in your system. 

# 2. Type in the terminal: "ml fsl" and "ml slicer"

# 3. Data should be structured in a determined way, check previous steps.  

#Please modify the following things before running: 
# -BASE : please modify input directory
#-----------------------------------------------------------------------

# import libraries
import os
import argparse
import sys
import subprocess

# Instantiate the parser
parser = argparse.ArgumentParser(description='Optional app description')
parser.add_argument('subjectID', type=str, help='ID of subject')
args = parser.parse_args()

# Set base directory
BASE = "/path/to/your/directory/"  #please modify

# Get arguments
SUBJ = args.subjectID

# Concatenate base and arguments
DIR = os.path.join(BASE)

# Exit script if base directory does not exist
if os.path.exists(DIR) == False:
   print("\n\n \033[0;37;41m Directory not found. Check subject ID and session. \033[0m \n\n")
   sys.exit()

# Create file paths necessary
T1_path = os.path.join(DIR, SUBJ+"/ses-T0/tmp/sub-X_ses-Y_space-mni_T1w.nii.gz")
FLAIR_path = os.path.join(DIR, SUBJ+"/ses-T0/tmp/sub-X_ses-Y_space-mni_FLAIR.nii.gz")
LESION_path = os.path.join(DIR, SUBJ+"/ses-T0/tmp/sub-X_ses-Y_space-mni_seg-lst.nii.gz")
BRAIN_path = os.path.join(DIR, SUBJ+"/ses-T0/tmp/sub-X_ses-Y_space-mni_brainmask.nii.gz")

## Slicer
# Set images linked upon opening
sliceCompositeNodes = slicer.util.getNodesByClass("vtkMRMLSliceCompositeNode")
defaultSliceCompositeNode = slicer.mrmlScene.GetDefaultNodeByClass("vtkMRMLSliceCompositeNode")
if not defaultSliceCompositeNode:
    defaultSliceCompositeNode = slicer.mrmlScene.CreateNodeByClass("vtkMRMLSliceCompositeNode")
    defaultSliceCompositeNode.UnRegister(None)  # CreateNodeByClass is factory method, need to unregister the result to prevent memory leaks
    slicer.mrmlScene.AddDefaultNode(defaultSliceCompositeNode)
sliceCompositeNodes.append(defaultSliceCompositeNode)
for sliceCompositeNode in sliceCompositeNodes:
    sliceCompositeNode.SetLinkedControl(True)

# Set intersection upon opening
sliceDisplayNodes = slicer.util.getNodesByClass("vtkMRMLSliceDisplayNode")
for sliceDisplayNode in sliceDisplayNodes:
  sliceDisplayNode.SetIntersectingSlicesVisibility(1)

# Load the volumes into Slicer
T1 = slicer.util.loadVolume(T1_path)
FLAIR = slicer.util.loadVolume(FLAIR_path)

# Set foreground and background
slicer.util.setSliceViewerLayers(background=FLAIR, foreground=T1, fit=True)

# Load segmentation into Slicer if not empty
command = ["fslstats", LESION_path, "-R"]
output = subprocess.check_output(command, universal_newlines=True)
output_values = output.strip().split()

if float(output_values[0]) != 0 or float(output_values[1]) != 0: 
    
    LESION = slicer.util.loadSegmentation(LESION_path)
    
    # Change properties of segmentation (opacity and color)
    segmentationNode=slicer.mrmlScene.GetFirstNodeByClass("vtkMRMLSegmentationNode")
    segmentationDisplayNode=segmentationNode.GetDisplayNode()
    segmentation=segmentationNode.GetSegmentation()

    segmentationDisplayNode.SetOpacity3D(0.8)

    segmentId = segmentation.GetSegmentIdBySegmentName("Segment_1")
    segmentationDisplayNode.SetSegmentOpacity2DOutline(segmentId, 0.0)
    segmentation.GetSegment(segmentId).SetColor(1,0,0)  # color should be set in segmentation node

else:
    print("\n\n \033[0;37;44m Lesion file empty, only structural images were loaded. \033[0m \n\n")

# Load the brain mask as a segmentation if it exists
if os.path.exists(BRAIN_path):
    BRAIN_segmentation = slicer.util.loadSegmentation(BRAIN_path)
    
    # Configure segmentation display properties
    brainSegmentationNode = slicer.mrmlScene.GetFirstNodeByClass("vtkMRMLSegmentationNode")
    brainSegmentationDisplayNode = brainSegmentationNode.GetDisplayNode()
    
    # Adjust opacity and color
    brainSegmentationDisplayNode.SetOpacity3D(0.5)
    brainSegmentationDisplayNode.SetOpacity2DFill(0.5)
    brainSegmentationDisplayNode.SetOpacity2DOutline(0.0)
    
    # Set color for all segments in the brain mask
    segmentation = brainSegmentationNode.GetSegmentation()
    for i in range(segmentation.GetNumberOfSegments()):
        segment = segmentation.GetNthSegment(i)
        segment.SetColor(0, 0, 1)  # Blue color
else:
    print(f"\n\n \033[0;37;41m Brain mask file not found: {BRAIN_path}. \033[0m \n\n")



# Set layout (Four-Up view)
#slicer.app.layoutManager().setLayout(slicer.vtkMRMLLayoutNode.SlicerLayoutFourUpView)


customLayout = """
<layout type="horizontal">
    <item>
      <view class=\"vtkMRMLSliceNode\" singletontag=\"Red\">
       <property name=\"orientation\" action=\"default\">Axial</property>
       <property name=\"viewlabel\" action=\"default\">R</property>
       <property name=\"viewcolor\" action=\"default\">#F34A33</property>
      </view>
     </item>
     <item>
      <view class=\"vtkMRMLSliceNode\" singletontag=\"Yellow\">
       <property name=\"orientation\" action=\"default\">Axial</property>
       <property name=\"viewlabel\" action=\"default\">Y</property>
       <property name=\"viewcolor\" action=\"default\">#EDD54C</property>
      </view>
     </item>
     <item>
      <view class=\"vtkMRMLSliceNode\" singletontag=\"Green\">
       <property name=\"orientation\" action=\"default\">Axial</property>
       <property name=\"viewlabel\" action=\"default\">G</property>
       <property name=\"viewcolor\" action=\"default\">#6EB04B</property>
      </view>
     </item>
    </layout>
    """
   

# Built-in layout IDs are all below 100, so you can choose any large random number
# for your custom layout ID.
customLayoutId=501

layoutManager = slicer.app.layoutManager()
layoutManager.layoutLogic().GetLayoutNode().AddLayoutDescription(customLayoutId, customLayout)

# Switch to the new custom layout
layoutManager.setLayout(customLayoutId)

# Add button to layout selector toolbar for this custom layout
viewToolBar = mainWindow().findChild("QToolBar", "ViewToolBar")
layoutMenu = viewToolBar.widgetForAction(viewToolBar.actions()[0]).menu()
layoutSwitchActionParent = layoutMenu  # use `layoutMenu` to add inside layout list, use `viewToolBar` to add next the standard layout list
layoutSwitchAction = layoutSwitchActionParent.addAction("My view") # add inside layout list
layoutSwitchAction.setData(customLayoutId)
layoutSwitchAction.setIcon(qt.QIcon(":Icons/Go.png"))
layoutSwitchAction.setToolTip("3D and slice view")
