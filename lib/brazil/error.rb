module Brazil
  class Error < RuntimeError
      attr_accessor :data
  end

  class UnknowStateException < Error; end
  class LoadException < Error; end

  class DBException < Error; end
  class NoDBInstanceException < DBException; end
  class DBConnectionException < DBException; end
  class DBExecuteSQLException < DBException; end
  class UnknownDBTypeException < DBException; end
  class NoVersionTableException < DBException; end
  class InvalidTargetVersionException < DBException; end
  class ValidVersionException < Error; end
  class ArgumentException < Error; end
  class RemoteAPIException < Error; end
  class VersionControlException < Error; end
  class AppSchemaVersionControlException < Error; end
end
