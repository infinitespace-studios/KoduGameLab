// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.Xna.Framework;
using TouchHook;
using System.Windows.Forms;

namespace Boku.Common
{
    public static class Input
    {
        #region Members
        // Contains a list of touch objects which store the data sent from TouchHook messages
        private static List<EventTouch> eventTouches = new List<EventTouch>();
        // Contains a static list of touch for this frame
        private static List<Touch> touchesThisFrame = new List<Touch>();
        // Contains a list of toucheventargs that needs processing
        private static List<TouchEventArgs> recordEventArgs = new List<TouchEventArgs>();
        
        private static WM_TouchHook cwTouchHook = null;

        #endregion Members

        #region Accessors

        public static int EventTouchCount
        {
            get
            {
                return eventTouches.Count;
            }
        }

        public static void ClearEvents()
        {
            eventTouches.Clear();
            touchesThisFrame.Clear();
        }

        /// <summary>
        /// Returns array of structs representing status of all touches during last frame
        /// (Read only, allocates new array)
        /// </summary>
        public static Touch[] touches
        {
            get { return touchesThisFrame.ToArray(); }
        }

        /// <summary>
        /// Property indicating whether the system handles multiple touches.
        /// </summary>
        public static bool multiTouchEnabled
        {
            get { return isMultiTouchEnabled; }
        }

        /// <summary>
        /// Number of touches. Guaranteed not to change throughout the frame. (Read Only).
        /// </summary>
        public static int touchCount
        {
            get { return touchCountThisFrame; }
        }

        #endregion Accessors

        #region Event Handlers

        private static List<TouchEventArgs> recordEventArgs = new List<TouchEventArgs>();

        private static void TouchDownHandler(object sender, TouchEventArgs e)
        {
            TouchEventArgs eva = new TouchEventArgs();
            eva.id = e.id;
            eva.time = e.time;

            recordEventArgs.Add(eva);

            EventTouch found = null;
            Vector2 screenPosition = ScreenToClient(e.x, e.y);
            foreach (EventTouch t in eventTouches)
            {
                if (t.fingerId == e.id)
                {
                    found = t;
                    //Console.WriteLine("TouchDown: t.postion= " + t.position.ToString() + ", phase=" + t.phase.ToString() + ", EventTouch=" + t.ToString());
                    break;
                }
            }

            // If we have found an old touch, lets compare the current time to the time stored in the touch
            // Then we can decide if its a tap or not.
            if (found != null)
            {
                //Console.WriteLine("Touch down on existing contact? {0}", found.fingerId);
                if (found.phase != TouchPhase.Ended)
                {
                    // This is duplicate from the touch hook?
                    Console.WriteLine("Touch contact exists: " + found.fingerId.ToString() + " -Touch.deltaTime is: " + found.deltaTime.ToString());
                    // This used to return from here. But we should have taken care of the duplicate events now
                    // so this isn't used except to log when we find a touch that should have been removed
                }

                Vector2 deltaPosition = screenPosition - found.position;
                found.deltaPosition = deltaPosition;
            }
            else
            {
                found = new EventTouch(screenPosition);
                found.fingerId = e.id;
                //found.deltaPosition = new Vector2();
                found.startTime = Time.WallClockTotalSeconds;
                //PV New place for the code
                found.isNew = true;
                // Set the phase to began
                found.phase = TouchPhase.Began;
                eventTouches.Add(found);
            }

            found.UpdateTimeOfChange(Time.WallClockTotalSeconds);
            found.position = screenPosition;
        }

        private static void TouchMoveHandler(object sender, TouchEventArgs e)
        {
            EventTouch found = null;
            Vector2 screenPosition = ScreenToClient(e.x, e.y);
            foreach (EventTouch t in eventTouches)
            {
                if (t.fingerId == e.id)
                {
                    found = t;
                    break;
                }
            }
        }

        private static void TouchUpHandler(object sender, TouchEventArgs e)
        {
            TouchEventArgs teaFind = recordEventArgs.Find(
            delegate(TouchEventArgs tea)
            {
                return tea.id == e.id;
            }
            );

            if (teaFind!=null)
            {
                recordEventArgs.Remove(teaFind);
            }

            EventTouch found = null;
            Vector2 screenPosition = ScreenToClient(e.x, e.y);
            foreach (EventTouch t in eventTouches)
            {
                if (t.fingerId == e.id)
                {
                    found = t;
                    //Console.WriteLine("TouchUp: t.postion= " + t.position.ToString() + ", phase=" + t.phase.ToString() + ", EventTouch=" + t.ToString() );

                    break;
                }
            }

            // If we don't have a touch then something went wrong... we should have up events on
            // existing touches, not new ones.
            if (found == null)
            {
                Console.WriteLine("Processing an UP event for a non-existant touch contact");

                return;
            }

            //FIXME: this was making it impossible to implement double tap - removing it seems to work, but more testing needed
            // to attempt to ascertain the actual problem it was supposedly trying to fix in the first place
            //if (found.timeOfLastChange == Time.WallClockTotalSeconds && found.phase != TouchPhase.Ended)
            //{
            //    Console.WriteLine("Touch Up on same event?  Setting delayed end... {0}", found.fingerId);

            //    // This is part of the bug where we get a touch down and up as part of the same message queue...
            //    // so to fix it we delay the touch end by one frame
            //    found.delayedEnd = true;
            //}

            found.UpdateTimeOfChange(Time.WallClockTotalSeconds);
            Vector2 deltaPosition = screenPosition - found.position;
            found.deltaPosition = deltaPosition;
            found.position = screenPosition;

            // Set the phase to ended
            if (found.delayedEnd == false)
            {
                // No delay was required for this touch up, as it was received with a different time stamp than
                // a touch-down.
                found.phase = TouchPhase.Ended;

                //Console.WriteLine("Undelayed touch up! id: " + found.fingerId.ToString() + ", phase: " + found.phase.ToString());
            }
            else
            {
                //Console.WriteLine("Delayed touch up! id: " + found.fingerId.ToString() + ", phase: " + found.phase.ToString());
            }
        }

        #endregion Event Handlers

        #region Public Methods

        public static void Init()
        {
            IntPtr mainformHandle = MainForm.Instance.Handle;
            IntPtr xnaControlHandle = XNAControl.Instance.Handle;
            cwTouchHook = new WM_TouchHook(xnaControlHandle, TouchHook.HookType.WH_CALLWNDPROC);
            //messageTouchHook = new WM_TouchHook(BokuGame.bokuGame.Window.Handle, TouchHook.HookType.WH_GETMESSAGE);
            WM_TouchHook.DisableNativePressAndHoldGesture = true;
            //messageTouchHook.InstallHook();
            cwTouchHook.InstallHook();

            cwTouchHook.TouchDown += new EventHandler<TouchEventArgs>(TouchDownHandler);
            cwTouchHook.TouchMove += new EventHandler<TouchEventArgs>(TouchMoveHandler);
            cwTouchHook.TouchUp += new EventHandler<TouchEventArgs>(TouchUpHandler);

            //messageTouchHook.TouchDown += new EventHandler<TouchEventArgs>(TouchDownHandler);
            //messageTouchHook.TouchMove += new EventHandler<TouchEventArgs>(TouchMoveHandler);
            //messageTouchHook.TouchUp += new EventHandler<TouchEventArgs>(TouchUpHandler);

            //store the max touch count detected at startup
            TouchInput.TouchAvailable = cwTouchHook.IsTouchAvailable();
            TouchInput.MaxTouchCount = cwTouchHook.GetMaxTouches();
        }

        public static Touch GetTouch(int index)
        {
            if (index < 0 || index >= touchesThisFrame.Count)
            {
                throw new IndexOutOfRangeException("Attempting to retrieve a touch using a bad index: " + index.ToString());
            }
            return touchesThisFrame[index];
        }

        private static string eventstring = "";
        public static string GetEventInfoString()
        {
            eventstring = "";
            foreach (EventTouch t in eventTouches)
            {
                eventstring += "id="+t.fingerId.ToString()
                              +",ph="+t.phase.ToString()
                              +",isOld="+t.isOld.ToString()
                              +",isNew="+t.isNew.ToString()
                              + "\n"

                               ;
            }
            eventstring += "TouchEventArg:\n";
            foreach (TouchEventArgs tea in recordEventArgs)
            {
                eventstring += "id=" + tea.id.ToString()
                               + "\n"
                               ;
            }
            return eventstring;
        }

        public static void Update()
        {
            //first remove old eventTouches, and Touches
            bool removedOld = true;
            while (removedOld)
            {
                removedOld = false;
                foreach (EventTouch eventTouch in eventTouches)
                {
                    if (eventTouch.isOld)
                    {
                        foreach (Touch touchThisFrame in touchesThisFrame)
                        {
                            if (touchThisFrame.fingerId == eventTouch.fingerId)
                            {
                                touchesThisFrame.Remove(touchThisFrame);
                                break;
                            }
                        }
                        eventTouches.Remove(eventTouch);
                        removedOld = true;
                        break;
                    }
                }
            }

            //add new eventTouches
            for (int i = 0; i < eventTouches.Count; ++i)
            {
                Touch currentTouchThisFrame = null;
                EventTouch eventTouch = eventTouches[i];
                // If this is a new touch, then lets add it
                if (eventTouch.isNew)
                {
                    foreach (Touch touchThisFrame in touchesThisFrame)
                    {
                        if (touchThisFrame.fingerId == eventTouch.fingerId)
                        {
                            currentTouchThisFrame = touchThisFrame;
                            break;
                        }
                    }

                    if (currentTouchThisFrame == null)
                    {
                        currentTouchThisFrame = new Touch();
                        currentTouchThisFrame.fingerId = eventTouch.fingerId;
                        touchesThisFrame.Add(currentTouchThisFrame);
                    }
                    eventTouch.isNew = false;
                }
                else
                {
                    foreach (Touch touchThisFrame in touchesThisFrame)
                    {
                        if (touchThisFrame.fingerId == eventTouch.fingerId)
                        {
                            currentTouchThisFrame = touchThisFrame;
                            break;
                        }
                    }
                    //??
                    if (currentTouchThisFrame == null)
                    {
                        Console.WriteLine("CurrentTouch not found!!");
                        continue;
                    }
                }

                switch (eventTouch.phase)
                {
                    case TouchPhase.Began:
                    {
                        // Set the {t} object to stationary, this will be updated to moved if needed or copied into the
                        // {touch} object next frame. This way we only see the Began phase for one frame.
                        eventTouch.phase = TouchPhase.Stationary;
                        eventTouch.isOld = false;

                        currentTouchThisFrame.phase = TouchPhase.Began;
                        break;
                    }

                    case TouchPhase.Moved:
                    {
                        // The touch move handler sets 'touches' list objects to the moved phase.
                        // Here in the update, we will transfer that phase info over to the 'touchesThisFrame'
                        // list, and the 'touches' list object gets set to Stationary again. In the absence
                        // of future move events, the 'touchesThisFrame' object will become stationary on
                        // the *following* frame.
                        eventTouch.phase = TouchPhase.Stationary;
                        currentTouchThisFrame.phase = TouchPhase.Moved;

                        break;
                    }

                    case TouchPhase.Stationary:
                    {
                        currentTouchThisFrame.phase = TouchPhase.Stationary;
                        break;
                    }

                    case TouchPhase.Ended:
                    {
                        currentTouchThisFrame.phase = TouchPhase.Ended;
                        eventTouch.isOld = true;

                        break;
                    }

                    default:
                        break;
                } //switch

                // Update the {t} objects time so it can be copied into the {touch} object
                eventTouch.UpdateDeltaTime(Time.WallClockTotalSeconds);

                // Set position with offset for Tutorial mode.
                currentTouchThisFrame.position = eventTouch.position - BokuGame.ScreenPosition;

                // HACK (****)  The touch position seems to be off.  Offset it here to be more accurate.
                // Need to really figure out why.
                currentTouchThisFrame.position += new Vector2(18, 18);

                currentTouchThisFrame.deltaPosition = eventTouch.deltaPosition;
                currentTouchThisFrame.fingerId = eventTouch.fingerId;
                //touch.tapCount = eventTouch.tapCount;

                currentTouchThisFrame.deltaTime = eventTouch.deltaTime;

                // Here we handle any touch-up messages whose processing is to be delayed by a frame.
                // We set the 'touches' phase to ended, which will then be propogated to
                // 'touchesThisFrame' on the following frame.
                if (eventTouch.delayedEnd)
                {
                    eventTouch.delayedEnd = false;
                    eventTouch.phase = TouchPhase.Ended;
                    Console.WriteLine("Delayed touch up has been processed. Touch.touchPhase will be Ended next frame! id: " + eventTouch.fingerId.ToString() + ", phase: " +
                        eventTouch.phase.ToString());
                }

            } //int i = 0; i < eventTouches.Count; ++i)

            touchCountThisFrame = touchesThisFrame.Count;

        }

        #endregion Public Methods

        #region Utils

        private static Vector2 ScreenToClient(int x, int y)
        {
            Vector2 mainFormLocation = new Vector2(MainForm.Instance.Location.X, MainForm.Instance.Location.Y);
            int marginX = (MainForm.Instance.Size.Width - MainForm.Instance.ClientSize.Width) / 2;
            int marginY = MainForm.Instance.Size.Height - MainForm.Instance.ClientSize.Height - marginX;
            // Margin values tuned by looking at my screen and seeing the dotsdisplay.
            // Note that the display doesn't seem quite centered.  It changes depending on it's size.
            // It's like it's not being rendered correctly.
            marginX = 28;
            marginY = 50;
            Vector2 screenPos = mainFormLocation + new Vector2(marginX, marginY);
            return new Vector2(x - screenPos.X, y - screenPos.Y);
        }

        #endregion Utils

        class EventTouch
        {
            public int fingerId;
            public Vector2 position;
            public Vector2 deltaPosition;
            //public int tapCount;
            public TouchPhase phase;
            public double startTime;

            public double timeOfLastChange;
            private float timeDelta;
            public float deltaTime
            {
                get { return timeDelta; }
            }

            public bool delayedEnd;
            public bool isNew;
            public bool isOld;

            /// <summary>
            /// Constructor!! Default initializes those values we care about.
            /// </summary>
            public EventTouch(Vector2 touchPosition)
            {
                position = touchPosition;

                deltaPosition = new Vector2();
                timeDelta = 0.0f;
                //tapCount = 0;
                phase = TouchPhase.Ended;

                timeOfLastChange = 0.0;
                delayedEnd = false;
                isNew = true;
                isOld = false;
            }

            internal void UpdateDeltaTime(double wallClock)
            {
                timeDelta = (float)(wallClock - timeOfLastChange);
                //Console.WriteLine("Updating DeltaTime: " + timeDelta.ToString() + ", id: " + fingerId.ToString());
            }

            internal void UpdateTimeOfChange(double wallClock)
            {
                timeDelta = 0.0f;
                timeOfLastChange = wallClock;
                //Console.WriteLine("Updating TimeOfChange, deltaTime is 0, id: " + fingerId.ToString());
            }
        }
    }

    public class Touch
    {
        public int fingerId;
        public Vector2 position;
        public Vector2 deltaPosition;
        public float deltaTime;
        //public int tapCount;
        public TouchPhase phase;
    }

    public enum TouchPhase
    {
        Began,
        Moved,
        Stationary,
        Ended
    }
}
