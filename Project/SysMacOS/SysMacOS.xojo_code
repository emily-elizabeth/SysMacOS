#tag Module
Protected Module SysMacOS
	#tag Method, Flags = &h0
		Function Icon(Extends file As FolderItem, iconSize As Integer = 32) As Picture
		  #if TargetMacOS
		    // copied from https://forum.xojo.com/t/get-picture-of-current-application-icon/25637/8
		    
		    declare function NSClassFromString lib "Cocoa" (aClassName as CFStringRef) as Ptr
		    declare function iconForFile lib "Cocoa" selector "iconForFile:" (obj_id as Ptr, fullPath as CFStringRef) as Ptr
		    declare function sharedWorkspace lib "Cocoa" selector "sharedWorkspace" (class_id as Ptr) as Ptr
		    declare sub CGContextDrawImage lib "Cocoa" (context as Ptr, rect as NSRect, image as Ptr)
		    declare function CGImageForProposedRect lib "Cocoa" selector "CGImageForProposedRect:context:hints:" (obj_id as Ptr, byref proposedDestRect as NSRect, referenceContext as Ptr, hints as Ptr) as Ptr
		    
		    dim imageRef as MemoryBlock = iconForFile(sharedWorkspace(NSClassFromString("NSWorkspace")), file.NativePath)
		    
		    dim p as new picture(iconSize, iconSize)
		    dim rect As NSRect
		    rect.w = iconSize
		    rect.h = iconSize
		    
		    // Convert the NSImage to CGImage
		    dim cntx as Ptr =ptr(p.Graphics.Handle(Graphics.HandleTypeCGContextRef))
		    dim cgPtr as Ptr = CGImageForProposedRect( imageRef, rect, nil, nil)
		    
		    // Draw the CGImage to our Xojo picture
		    CGContextDrawImage cntx, rect, cgPtr
		    
		    Return p
		  #endif
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub PostUserNotification(title As String, subTitle As String, informativeText As String, contentImage As Picture, Optional identifier As String)
		  #if TargetCocoa
		    Declare Function alloc Lib "Cocoa" Selector "alloc" (classRef As Ptr) As Ptr
		    Declare Function defaultUserNotificationCenter Lib "Cocoa" Selector "defaultUserNotificationCenter" (classRef As Ptr) As Ptr
		    Declare Function init Lib "Cocoa" Selector "init" (classRef As Ptr) As Ptr
		    Declare Function initWithCGImageSize Lib "Cocoa" Selector "initWithCGImage:size:" (classRef As Ptr, CGImageRef As Ptr, size As NSSize) As Ptr
		    Declare Function NSClassFromString Lib "Cocoa" (className As CFStringRef) As Ptr
		    Declare Sub CFRelease Lib "CoreFoundation" (CFTypeRef As Ptr)
		    Declare Sub deliverNotification Lib "Cocoa" Selector "deliverNotification:" (defaultUserNotificationCenter As Ptr, notification As Ptr)
		    Declare Sub setTitle Lib "Cocoa" Selector "setTitle:" (instanceRef As Ptr, caption As CFStringRef)
		    Declare Sub setSubtitle Lib "Cocoa" Selector "setSubtitle:" (instanceRef As Ptr, caption As CFStringRef)
		    Declare Sub setInformativeText Lib "Cocoa" Selector "setInformativeText:" (instanceRef As Ptr, text As CFStringRef)
		    Declare Sub setIdentifier Lib "Cocoa" Selector "setIdentifier:" (instanceRef As Ptr, value As CFStringRef)
		    Declare Sub setContentImage Lib "Cocoa" Selector "setContentImage:" (instanceRef As Ptr, aNSImage As Ptr)
		    
		    Static NSUserNotificationClass As Ptr = NSClassFromString("NSUserNotification")
		    Static NSUserNotificationCenterClass As Ptr = NSClassFromString("NSUserNotificationCenter")
		    Static NSUserNotificationCenterDefaultCenter As Ptr = defaultUserNotificationCenter(NSUserNotificationCenterClass)
		    Static NSImageClass As Ptr = NSClassFromString("NSImage")
		    
		    // create the user notification instance and populate the properties
		    DIM NSUserNotificationInstance As Ptr = init(alloc(NSUserNotificationClass))
		    
		    if (title <> "") then
		      setTitle NSUserNotificationInstance, title
		    end if
		    
		    if (subTitle <> "") then
		      setSubtitle NSUserNotificationInstance, subTitle
		    end if
		    
		    if (informativeText <> "") then
		      setInformativeText NSUserNotificationInstance, informativeText
		    end if
		    
		    if (identifier <> "") then
		      setIdentifier NSUserNotificationInstance, identifier
		    else
		      setIdentifier NSUserNotificationInstance, App.ExecutableFile.Name
		    end if
		    
		    if (contentImage <> Nil) then
		      DIM aCGImage As Ptr = contentImage.CopyOSHandle(Picture.HandleType.MacCGImage)
		      if (aCGImage <> Nil) then
		        DIM size As NSSize
		        DIM aNSImage As Ptr = initWithCGImageSize(alloc(NSImageClass), aCGImage, size)
		        
		        setContentImage NSUserNotificationInstance, aNSImage
		        CFRelease aCGImage
		      end if
		    end if
		    
		    if (NSUserNotificationInstance <> Nil) then
		      deliverNotification NSUserNotificationCenterDefaultCenter, NSUserNotificationInstance
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub RequestUserAttention(critical As Boolean = FALSE)
		  #if TargetCocoa
		    Declare Function NSClassFromString Lib "Cocoa" (aClassName As CFStringRef) As Ptr
		    Declare Function NSSelectorFromString Lib "Cocoa" (aSelectorName As CFStringRef) As Ptr
		    Declare Function RespondsToSelector Lib "Cocoa" Selector "respondsToSelector:" (NSApp As Ptr, aSelector As Ptr) As Boolean
		    Declare Function SharedApplication Lib "Cocoa" Selector "sharedApplication" (aClass As Ptr) As Ptr
		    Declare Function RequestUserAttention Lib "Cocoa" Selector "requestUserAttention:" (NSApp As Ptr, requestType As Integer) As Integer
		    
		    Const NSCriticalRequest = 0
		    Const NSInformationalRequest = 10
		    
		    DIM NSApp As Ptr = SharedApplication(NSClassFromString("NSApplication"))
		    DIM aSelector As Ptr = NSSelectorFromString("requestUserAttention:")
		    
		    if (RespondsToSelector(NSApp, aSelector)) then
		      if (critical) then
		        Call RequestUserAttention(NSApp, NSCriticalRequest)
		      else
		        Call RequestUserAttention(NSApp, NSInformationalRequest)
		      end if
		    end if
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Resize(Extends inWindow as DesktopWindow, width as Integer, height as Integer)
		  #if TargetCocoa
		    // If you copy this method, you will need the following structure: NSRect
		    
		    Declare Function NSClassFromString Lib "Cocoa" (aClassName As CFStringRef) As Ptr
		    Declare Function NSSelectorFromString Lib "Cocoa" (aSelectorName As CFStringRef) As Ptr
		    Declare Function RespondsToSelector Lib "Cocoa" Selector "respondsToSelector:" (NSWindow As Ptr, aSelector As Ptr) As Boolean
		    Declare Function Frame Lib "Cocoa" Selector "frame" (NSWindow As Ptr) As NSRect
		    Declare Sub SetFrameDisplayAnimate Lib "Cocoa" Selector "setFrame:display:animate:" (NSWindow As Ptr, inNSRect As NSRect, Display As Boolean, Animate As Boolean)
		    
		    DIM FrameSelector As Ptr = NSSelectorFromString("frame")
		    DIM SetFrameDisplayAnimateSelector As Ptr = NSSelectorFromString("setFrame:display:animate:")
		    
		    if (RespondsToSelector(inWindow.Handle, FrameSelector)) AND (RespondsToSelector(inWindow.Handle, SetFrameDisplayAnimateSelector)) then
		      DIM deltaWidth As CGFloat = width - inWindow.Width
		      DIM deltaHeight As CGFloat = height - inWindow.Height
		      
		      DIM frameRect As NSRect = Frame(inWindow.Handle)
		      frameRect.h = frameRect.h + deltaHeight
		      frameRect.Y = frameRect.Y - deltaHeight
		      frameRect.w = frameRect.w + deltaWidth
		      
		      SetFrameDisplayAnimate inWindow.Handle, frameRect, TRUE, TRUE
		    end if
		    
		  #else
		    me.Width = width
		    me.Height = height
		  #endif
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetAlternate(Extends aMenuItem As DesktopMenuItem, Assigns value As Boolean)
		  #if TargetCocoa
		    Declare Sub SetAlternate_ Lib "Cocoa" Selector "setAlternate:" (aNSMenuItem As Ptr, value As Boolean)
		    SetAlternate_ aMenuItem.Handle, value
		  #endif
		End Sub
	#tag EndMethod


	#tag Structure, Name = NSRect, Flags = &h21
		x as Double
		  y as Double
		  w as Double
		h as Double
	#tag EndStructure

	#tag Structure, Name = NSSize, Flags = &h21
		width as Double
		height as Double
	#tag EndStructure


End Module
#tag EndModule
