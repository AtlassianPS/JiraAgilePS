using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;

namespace AtlassianPS
{
    namespace JiraAgilePS
    {
        public enum BoardType
        {
            kanban,
            scrum,
            simple
        }

        public enum SprintState
        {
            active,
            future,
            closed
        }

        public class Board
        {
            public Board(UInt64 value) { Id = value; }
            public Board(String value)
            {
                UInt64 _id;
                if (UInt64.TryParse(value, out _id))
                    Id = _id;
                else
                    Name = value;
            }
            public Board() { }

            public UInt64 Id { get; set; }
            public String Name { get; set; }
            public BoardType Type { get; set; }
            public Uri Self { get; set; }

            public override string ToString()
            {
                return Name;
            }
        }

        public class Sprint
        {
            public Sprint(UInt64 value) { Id = value; }
            public Sprint(String value)
            {
                UInt64 _id;
                if (UInt64.TryParse(value, out _id))
                    Id = _id;
                else
                    Name = value;
            }
            public Sprint() { }

            public UInt64 Id { get; set; }
            public String Name { get; set; }
            public SprintState State { get; set; }
            public Nullable<DateTime> StartDate { get; set; }
            public Nullable<DateTime> EndDate { get; set; }
            public Nullable<DateTime> CompleteDate { get; set; }
            public UInt64 OriginBoardId { get; set; }
            public String Goal { get; set; }
            public Uri Self { get; set; }

            public override string ToString()
            {
                return Name;
            }
        }

        public class Epic
        {
            public Epic(UInt64 value) { Id = value; }
            public Epic(String value)
            {
                UInt64 _id;
                if (UInt64.TryParse(value, out _id))
                    Id = _id;
                else
                    Name = value;
            }
            public Epic() { }

            public UInt64 Id { get; set; }
            public String Key { get; set; }
            public String Name { get; set; }
            public String Summary { get; set; }
            public String Color { get; set; }
            public Boolean Done { get; set; }
            public Uri Self { get; set; }

            public override string ToString()
            {
                if (!String.IsNullOrWhiteSpace(Name))
                    return Name;
                if (!String.IsNullOrWhiteSpace(Key))
                    return Key;

                return Id.ToString();
            }
        }
    }
}
