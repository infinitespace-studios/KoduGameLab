// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.


using System;
using System.Diagnostics;
using System.IO;
using System.Collections.Generic;
using System.Collections;
using System.Linq;
using System.Text;

using Boku.Programming;
using Boku.Base;

namespace Boku.Analyses
{
    public class ObjectAnalysis
    {
        private int actors = 0;
        private int totalRules = 0;
        private int blankActors = 0;
        Dictionary<GameActor, int> rulesPerActor = new Dictionary<GameActor, int>();
        List<KeyValuePair<GameActor, int>> indentedRulesPerActor = new List<KeyValuePair<GameActor, int>>();
        List<KeyValuePair<GameActor, int>> notRulesPerActor = new List<KeyValuePair<GameActor, int>>();
        List<KeyValuePair<GameActor, int>> creatableActor = new List<KeyValuePair<GameActor, int>>();

        private WriteToFile wf = new WriteToFile();

        public ObjectAnalysis()
        {
            //default constructor
        }
        public void beginAnalysis(string file)
        {
            processActors();
            searchForUnreachable();
            uncoverTileUsage();
           // createSummary(file);
            summarize(file);
        }

        /*
         * Identifies unreach
         */
        private void searchForUnreachable()
        {
            foreach (GameActor actor in InGame.inGame.gameThingList)
            {
                //maps an int to a boolean, level to if it is reached, per actor
                Dictionary<int, bool> reached = new Dictionary<int, bool>();
                List<int> pages = new List<int>();
                for (int i = 0; i < actor.Brain.tasks.Count; i++)
                {
                    Task task = actor.Brain.tasks[i];

                    // the page has some rules
                    if (task.reflexes.Count > 0)
                    {
                        int taskid = i + 1;
                        pages.Add(taskid);
                        if (taskid == 1)
                        {
                            reached.Add(taskid, true);                           
                        }
                        else
                        {
                            // add it to the list
                            reached.Add(taskid, false);
                        }
                    }
                }
                int destination = 1;
                //for each page in the hashtable, make sure it's reachable
                foreach (int index in pages)
                {
                    //grab the kode, look for jumps
                    Task task = actor.Brain.tasks[index-1];
                    //go through the rules
                    foreach (Reflex rule in task.reflexes)
                    {
                        // if we have a jump!
                        if (rule.Data.Actuator == null)
                        {
                            continue;
                        }
                        if (rule.Data.Actuator.upid == "actuator.switchtask")
                        {
                            //find the modifier with the page
                            for (int i = 0; i < rule.Data.Modifiers.Count; i++)
                            {
                                Modifier m = rule.Data.Modifiers[i];
                                if (m.label.Contains("page"))
                                {
                                    //get the number!
                                    string[] str = m.label.Split(' ');
                                    destination = Convert.ToUInt16(str[1]);

                                    //check if the key we're jumping to exists
                                    if (!reached.ContainsKey(destination))
                                    {
            Debug.Assert(false, "Not Impl");
                                        //we're jumping to a blank page...this is a different kind of error
                                        //TODO: Process later!!!
                                    }
                                    else
                                    {
                                        reached[destination] = true;
                                    }
                                }
                            }
                        }
                   
                    }

                }
                foreach (KeyValuePair<int, bool> de in reached)
                {
                    if (de.Value == false)
                    {
            Debug.Assert(false, "Not Impl");
                    }
                }

            } //foreach actor
        }

        public void uncoverTileUsage()
        {
            Dictionary<string, int> usage = new Dictionary<string, int>();
            foreach (GameActor actor in InGame.inGame.gameThingList)
            {
                for (int i = 0; i < actor.Brain.tasks.Count; i++)
                {
                    Task task = actor.Brain.tasks[i];
                    foreach (Reflex reflex in task.reflexes)
                    {
                        //get each tile
                        if (reflex.Data.Sensor != null)
                        {
                            updateUsage(usage, reflex.Data.Sensor.upid);
                        }
                        if (reflex.Data.Filters != null)                            
                        {
                            foreach (Filter f in reflex.Data.Filters)
                            {
                                updateUsage(usage, f.upid);
                            }
                        }
                        if (reflex.Data.Selector != null)
                        {
                            updateUsage(usage, reflex.Data.Selector.upid);
                        }
                        if (reflex.Data.Actuator != null)
                        {
                            updateUsage(usage, reflex.Data.Actuator.upid);
                        }
                        if (reflex.Data.Modifiers != null)
                        {
                            foreach (Modifier m in reflex.Data.Modifiers)
                            {
                                updateUsage(usage, m.upid);
                            }
                        }
                    }
                }
            }
            Debug.Assert(false, "Not Impl");
        }

        private void updateUsage(Dictionary<string, int> usage, string id)
        {
            if (usage.ContainsKey(id))
            {
                int temp = usage[id];
                temp++;
                usage[id] = temp;
            }else {
                usage.Add(id, 1);
            }
        }

        public void createSummary(string file)
        {
            Debug.Assert(false, "Not Impl");
        }

        public void summarize(string file)
        {
            Debug.Assert(false, "Not Impl");
        }

        //iterates over all actors
        public void processActors()
        {
            for (int i = 0; i < InGame.inGame.gameThingList.Count; i++)
            {
                actors++;
                GameActor actor = InGame.inGame.gameThingList[i] as GameActor;

                if (actor != null)
                {
                    processActorForRules(actor);
                }
            }
        }

        //processes a single actor
        public void processActorForRules(GameActor actor)
        {
            int rules = 0;
            int indented = 0;
            int sumIndents = 0;
            int not = 0;

            if (actor.CreatableId != Guid.Empty)
            {
                creatableActor.Add(new KeyValuePair<GameActor, int>(actor, 1));
            }
            else
            {
                creatableActor.Add(new KeyValuePair<GameActor, int>(actor, 0));
            }

            //a task is a page, a reflex is a rule?
            for (int i = 0; i < actor.Brain.tasks.Count; i++)
            {
                Task task = actor.Brain.tasks[i];
                if (task.reflexes.Count == 0)
                {
                    continue;
                }
                rules += task.reflexes.Count;
                foreach (Reflex r in task.reflexes)
                {
                    if (r.Indentation > 0)
                    {
                        indented++;
                        sumIndents += r.Indentation;
                    }
                    foreach (Filter f in r.Filters)
                    {
                        if (f.upid == "filter.not") //not filter
                        {
                            not++;
                        }
                    }
                }

            }
            totalRules += rules;
            if (rules == 0)
            {
                blankActors++;
            }
            rulesPerActor.Add(actor, rules);
            indentedRulesPerActor.Add(new KeyValuePair<GameActor, int>(actor, indented)); //number of indented rules
            notRulesPerActor.Add(new KeyValuePair<GameActor, int>(actor, not)); // number of rules with not
        }
    }
}
