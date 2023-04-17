import zipfile
import tarfile
import os
from celery import Celery
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from modelos import File

celery_app = Celery(__name__, broker='redis://:lOGleSPirDOLEYsiceWlemPtO@10.130.13.4:6379/0')

# Configure SQLAlchemy to use the PostgreSQL database
engine = create_engine('postgresql://converter_db:ckhAMLIteFlYheRptAteapeze@10.130.13.6:5432/conversion')
Session = sessionmaker(bind=engine)
session = Session()

def to_zip(file_path, destination_path):
    processed_filename = destination_path + '.zip'
    with zipfile.ZipFile(processed_filename, 'w') as zip_file:
        zip_file.write(file_path)
    return processed_filename

def to_tar_gz(file_path, destination_path):
    processed_filename = destination_path + '.tar.gz'
    with tarfile.open(destination_path + '.tar.gz', 'w:gz') as tar:
        print(f'file url{file_path}')
        tar.add(file_path, arcname=os.path.basename(file_path))
    return processed_filename

def to_tar_bz2(file_path, destination_path):
    processed_filename = destination_path + '.tar.bz2'
    with tarfile.open(destination_path + '.tar.bz2', 'w:bz2') as tar:
        tar.add(file_path, arcname=os.path.basename(file_path))
    return processed_filename
@celery_app.task(name='proccess_file')
def proccess_file(file_id, filename, new_format, fecha):
    UPLOAD_FOLDER = './uploads'
    PROCESS_FOLDER = './processed'
    filenameParts = filename.split('.')

    log_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'log_conversion.txt')
    with open(log_file_path, 'a+') as file:
        file.write('{} to {} - solicitud de conversion: {}\n'.format(filename, new_format, fecha))

    formats = {
        'zip': to_zip,
        'tar_gz': to_tar_gz,
        'tar_bz2': to_tar_bz2
    }

    # Query the database for all users
    # file = session.query(File).filter_by(id=file_id).first()
    # print(f'found file:{file}')

    if new_format in formats.keys():
        print(f"calling {new_format}")
        func = formats[new_format]
        print(f"function: {func}")
        processed_filename = func(os.path.join(UPLOAD_FOLDER, filename), os.path.join(PROCESS_FOLDER, filenameParts[0]))
        print(f"destination: {os.path.join(PROCESS_FOLDER, filename)}")
        file = session.query(File).filter_by(id=file_id).first()
        processed_filename_parts = processed_filename.split('/')
        file.processed_filename = processed_filename_parts[-1]
        file.state = 'PROCESSED'
        session.add(file)
        session.commit()
    else:
        print("Invalid format")