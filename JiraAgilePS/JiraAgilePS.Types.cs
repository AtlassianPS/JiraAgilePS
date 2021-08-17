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
            scrum
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

    }
}
