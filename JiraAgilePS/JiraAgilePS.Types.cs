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

        public enum SprintState
        {
            active,
            future,
            closed
        }

        internal static class JiraAgileTransform
        {
            public static bool IsNumericType(object value)
            {
                return value is int || value is long || value is short || value is byte
                    || value is uint || value is ulong || value is ushort || value is sbyte;
            }

            public static bool TryConvertToUInt64(object value, out UInt64 result)
            {
                result = 0;
                if (value == null) { return false; }

                if (value is UInt64)
                {
                    result = (UInt64)value;
                    return true;
                }

                if (IsNumericType(value))
                {
                    try
                    {
                        var signedValue = Convert.ToInt64(value);
                        if (signedValue < 0) { return false; }
                        result = (UInt64)signedValue;
                        return true;
                    }
                    catch
                    {
                        return false;
                    }
                }

                UInt64 parsed;
                if (UInt64.TryParse(value.ToString(), out parsed))
                {
                    result = parsed;
                    return true;
                }

                return false;
            }

            public static bool IsJiraAgileDomainObject(object value)
            {
                if (value == null) { return false; }

                var pso = value as PSObject;
                if (pso != null)
                {
                    if (pso.TypeNames != null)
                    {
                        foreach (var typeName in pso.TypeNames)
                        {
                            if (!string.IsNullOrEmpty(typeName)
                                && typeName.StartsWith("AtlassianPS.JiraAgilePS.", StringComparison.Ordinal))
                            {
                                return true;
                            }
                        }
                    }

                    value = pso.BaseObject;
                    if (value == null) { return false; }
                }

                var valueType = value.GetType();
                return valueType != null
                    && string.Equals(valueType.Namespace, "AtlassianPS.JiraAgilePS", StringComparison.Ordinal);
            }

            public static object TransformOrFanout(object inputData, Func<object, object> perItem)
            {
                if (inputData == null) { return null; }

                var pso = inputData as PSObject;
                object value = pso != null ? pso.BaseObject : inputData;

                if (value is string) { return perItem(inputData); }
                if (value is IDictionary) { return perItem(inputData); }

                var enumerable = value as IEnumerable;
                if (enumerable != null)
                {
                    var results = new List<object>();
                    foreach (var item in enumerable)
                    {
                        results.Add(perItem(item));
                    }
                    return results.ToArray();
                }

                return perItem(inputData);
            }

            public static Uri ToUri(object value)
            {
                if (value == null) { return null; }

                var uri = value as Uri;
                if (uri != null) { return uri; }

                var text = value.ToString();
                if (string.IsNullOrWhiteSpace(text)) { return null; }

                return new Uri(text, UriKind.RelativeOrAbsolute);
            }

            public static bool HasAnyProperty(PSObject pso, params string[] propertyNames)
            {
                if (pso == null || pso.Properties == null) { return false; }
                foreach (var propertyName in propertyNames)
                {
                    if (pso.Properties[propertyName] != null) { return true; }
                }
                return false;
            }
        }

        public abstract class JiraAgileTransformationAttribute : ArgumentTransformationAttribute
        {
            protected abstract Type TargetType { get; }
            protected abstract object FromString(string value);

            protected virtual object FromNumericScalar(UInt64 value) { return null; }
            protected virtual bool ShouldMapLegacyObject(PSObject pso) { return false; }
            protected virtual object MapLegacyObject(PSObject pso) { return null; }

            public sealed override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
            {
                return JiraAgileTransform.TransformOrFanout(inputData, TransformOne);
            }

            private object TransformOne(object inputData)
            {
                if (inputData == null) { return null; }

                var pso = inputData as PSObject;
                object value = pso != null ? pso.BaseObject : inputData;

                var targetType = TargetType;
                if (targetType.IsInstanceOfType(value)) { return value; }

                // Preserve binder fallthrough for competing ValueFromPipeline
                // parameter sets when the piped value is another JiraAgilePS
                // domain type.
                if (JiraAgileTransform.IsJiraAgileDomainObject(inputData))
                {
                    return inputData;
                }

                UInt64 numericValue;
                if (JiraAgileTransform.TryConvertToUInt64(value, out numericValue))
                {
                    var numeric = FromNumericScalar(numericValue);
                    if (numeric != null) { return numeric; }
                }

                var text = value as string;
                if (text != null)
                {
                    if (string.IsNullOrWhiteSpace(text))
                    {
                        throw new ArgumentTransformationMetadataException(
                            "Cannot bind an empty or whitespace string to a " + targetType.FullName + " parameter.");
                    }

                    return FromString(text);
                }

                if (ShouldMapLegacyObject(pso))
                {
                    var mapped = MapLegacyObject(pso);
                    if (mapped != null) { return mapped; }
                }
                return inputData;
            }
        }

        [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
        public sealed class BoardTransformationAttribute : JiraAgileTransformationAttribute
        {
            protected override Type TargetType { get { return typeof(Board); } }
            protected override object FromString(string value) { return new Board(value); }
            protected override object FromNumericScalar(UInt64 value) { return new Board(value); }

            protected override bool ShouldMapLegacyObject(PSObject pso)
            {
                return JiraAgileTransform.HasAnyProperty(pso, "Id", "id", "Name", "name", "Type", "type", "Self", "self");
            }

            protected override object MapLegacyObject(PSObject pso)
            {
                var board = new Board();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "Id":
                        case "id":
                        case "ID":
                            UInt64 id;
                            if (JiraAgileTransform.TryConvertToUInt64(prop.Value, out id))
                            {
                                board.Id = id;
                            }
                            break;
                        case "Name":
                        case "name":
                            board.Name = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Type":
                        case "type":
                            if (prop.Value != null)
                            {
                                BoardType boardType;
                                if (Enum.TryParse<BoardType>(prop.Value.ToString(), true, out boardType))
                                {
                                    board.Type = boardType;
                                }
                            }
                            break;
                        case "Self":
                        case "self":
                            board.Self = JiraAgileTransform.ToUri(prop.Value);
                            break;
                    }
                }

                return board;
            }
        }

        [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
        public sealed class SprintTransformationAttribute : JiraAgileTransformationAttribute
        {
            protected override Type TargetType { get { return typeof(Sprint); } }
            protected override object FromString(string value) { return new Sprint(value); }
            protected override object FromNumericScalar(UInt64 value) { return new Sprint(value); }

            protected override bool ShouldMapLegacyObject(PSObject pso)
            {
                return JiraAgileTransform.HasAnyProperty(pso, "Id", "id", "Name", "name", "State", "state", "Self", "self");
            }

            protected override object MapLegacyObject(PSObject pso)
            {
                var sprint = new Sprint();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "Id":
                        case "id":
                        case "ID":
                            UInt64 id;
                            if (JiraAgileTransform.TryConvertToUInt64(prop.Value, out id))
                            {
                                sprint.Id = id;
                            }
                            break;
                        case "Name":
                        case "name":
                            sprint.Name = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "State":
                        case "state":
                            if (prop.Value != null)
                            {
                                SprintState sprintState;
                                if (Enum.TryParse<SprintState>(prop.Value.ToString(), true, out sprintState))
                                {
                                    sprint.State = sprintState;
                                }
                            }
                            break;
                        case "StartDate":
                        case "startDate":
                            DateTime startDate;
                            if (prop.Value != null && DateTime.TryParse(prop.Value.ToString(), out startDate))
                            {
                                sprint.StartDate = startDate;
                            }
                            break;
                        case "EndDate":
                        case "endDate":
                            DateTime endDate;
                            if (prop.Value != null && DateTime.TryParse(prop.Value.ToString(), out endDate))
                            {
                                sprint.EndDate = endDate;
                            }
                            break;
                        case "CompleteDate":
                        case "completeDate":
                            DateTime completeDate;
                            if (prop.Value != null && DateTime.TryParse(prop.Value.ToString(), out completeDate))
                            {
                                sprint.CompleteDate = completeDate;
                            }
                            break;
                        case "OriginBoardId":
                        case "originBoardId":
                            UInt64 originBoardId;
                            if (JiraAgileTransform.TryConvertToUInt64(prop.Value, out originBoardId))
                            {
                                sprint.OriginBoardId = originBoardId;
                            }
                            break;
                        case "Goal":
                        case "goal":
                            sprint.Goal = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Self":
                        case "self":
                            sprint.Self = JiraAgileTransform.ToUri(prop.Value);
                            break;
                    }
                }

                return sprint;
            }
        }

        [AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter, AllowMultiple = false)]
        public sealed class EpicTransformationAttribute : JiraAgileTransformationAttribute
        {
            protected override Type TargetType { get { return typeof(Epic); } }
            protected override object FromString(string value) { return new Epic(value); }
            protected override object FromNumericScalar(UInt64 value) { return new Epic(value); }

            protected override bool ShouldMapLegacyObject(PSObject pso)
            {
                return JiraAgileTransform.HasAnyProperty(pso, "Id", "id", "Key", "key", "Name", "name", "Self", "self");
            }

            protected override object MapLegacyObject(PSObject pso)
            {
                var epic = new Epic();
                foreach (var prop in pso.Properties)
                {
                    switch (prop.Name)
                    {
                        case "Id":
                        case "id":
                        case "ID":
                            UInt64 id;
                            if (JiraAgileTransform.TryConvertToUInt64(prop.Value, out id))
                            {
                                epic.Id = id;
                            }
                            break;
                        case "Key":
                        case "key":
                            epic.Key = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Name":
                        case "name":
                            epic.Name = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Summary":
                        case "summary":
                            epic.Summary = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Color":
                        case "color":
                            epic.Color = prop.Value as string ?? (prop.Value != null ? prop.Value.ToString() : null);
                            break;
                        case "Done":
                        case "done":
                            bool done;
                            if (prop.Value != null && bool.TryParse(prop.Value.ToString(), out done))
                            {
                                epic.Done = done;
                            }
                            break;
                        case "Self":
                        case "self":
                            epic.Self = JiraAgileTransform.ToUri(prop.Value);
                            break;
                    }
                }

                return epic;
            }
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
